// @ts-nocheck
/// <reference types="jsr:@supabase/functions-js/edge-runtime.d.ts" />

import { createClient as createSupa } from "npm:@supabase/supabase-js@2";

// ---------- Env (uden SUPABASE_* prefix i secrets) ----------
const SUPABASE_URL = Deno.env.get("PROJECT_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("ANON_KEY") ?? "";
const IAP_VERIFY_MODE = (Deno.env.get("IAP_VERIFY_MODE") ?? "stub").toLowerCase();

const APPLE_SHARED_SECRET = Deno.env.get("APPLE_SHARED_SECRET");        // (prod) iOS
const GOOGLE_SA_JSON = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");     // (prod) Android

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("Missing PROJECT_URL or SERVICE_ROLE_KEY");
}

// ---------- Helper: user-id fra Authorization ----------
async function getUserIdFromAuth(req: Request): Promise<string | null> {
    const anon = createSupa(SUPABASE_URL, SUPABASE_ANON_KEY, {
        global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data, error } = await anon.auth.getUser();
    if (error || !data?.user) return null;
    return data.user.id;
}

// ---------- Upsert premium ----------
async function grantPremium(userId: string) {
    const admin = createSupa(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { error } = await admin
        .from("user_entitlements")
        .upsert({ user_id: userId, premium: true })
        .eq("user_id", userId);
    if (error) throw error;
}

/* =========================
   PROD-verifikation (valgfrit)
   ========================= */

type ServiceAccount = {
    client_email: string;
    private_key: string;
    token_uri?: string;
};

async function verifyApple(receipt: string, expectedProductId: string) {
    if (!APPLE_SHARED_SECRET) return { valid: false, details: "Missing APPLE_SHARED_SECRET" };
    const endpoints = [
        "https://buy.itunes.apple.com/verifyReceipt",
        "https://sandbox.itunes.apple.com/verifyReceipt",
    ];
    for (const url of endpoints) {
        const resp = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                "receipt-data": receipt,
                "password": APPLE_SHARED_SECRET,
                "exclude-old-transactions": true,
            }),
        });
        const data = await resp.json();
        if (data.status === 21007) continue; // sandbox fallback
        if (data.status !== 0) return { valid: false, details: data };
        const inApps = data.latest_receipt_info ?? data.receipt?.in_app ?? [];
        const match = inApps.find((i: any) => i.product_id === expectedProductId);
        return { valid: Boolean(match), details: data };
    }
    return { valid: false, details: { error: "Apple verify failed" } };
}

async function getGoogleAccessToken(sa: ServiceAccount) {
    const now = Math.floor(Date.now() / 1000);
    const header = { alg: "RS256", typ: "JWT" };
    const scope = "https://www.googleapis.com/auth/androidpublisher";
    const aud = sa.token_uri ?? "https://oauth2.googleapis.com/token";
    const claim = { iss: sa.client_email, scope, aud, exp: now + 3600, iat: now };

    const enc = new TextEncoder();
    const b64u = (x: Uint8Array) =>
        btoa(String.fromCharCode(...x)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
    const headerB64 = b64u(enc.encode(JSON.stringify(header)));
    const claimB64 = b64u(enc.encode(JSON.stringify(claim)));
    const unsigned = `${headerB64}.${claimB64}`;

    // PEM → ArrayBuffer (PKCS8)
    const pkcs8Der = (() => {
        // @ts-ignore
        const pem = sa.private_key.replace("-----BEGIN PRIVATE KEY-----", "")
            .replace("-----END PRIVATE KEY-----", "").replace(/\s+/g, "");
        const raw = atob(pem);
        const buf = new Uint8Array(raw.length);
        for (let i = 0; i < raw.length; i++) buf[i] = raw.charCodeAt(i);
        return buf.buffer;
    })();

    const key = await crypto.subtle.importKey(
        "pkcs8",
        pkcs8Der,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"],
    );
    const sig = new Uint8Array(await crypto.subtle.sign(
        { name: "RSASSA-PKCS1-v1_5" }, key, enc.encode(unsigned),
    ));
    const jwt = `${unsigned}.${b64u(sig)}`;

    const resp = await fetch(aud, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: jwt,
        }),
    });
    const data = await resp.json();
    if (!data.access_token) throw new Error("Google OAuth token error");
    return data.access_token as string;
}

async function verifyGoogle(packageName: string, productId: string, purchaseToken: string) {
    if (!GOOGLE_SA_JSON) return { valid: false, details: "Missing GOOGLE_SERVICE_ACCOUNT_JSON" };
    const sa = JSON.parse(GOOGLE_SA_JSON) as ServiceAccount;
    const token = await getGoogleAccessToken(sa);

    const url =
        `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(
            packageName)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

    const resp = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
    if (!resp.ok) return { valid: false, details: await resp.text() };
    const data = await resp.json();
    return { valid: data.purchaseState === 0, details: data }; // 0=Purchased
}

/* =========== Handler =========== */
Deno.serve(async (req) => {
    try {
        if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

        const userId = await getUserIdFromAuth(req);
        if (!userId) return new Response("Unauthorized", { status: 401 });

        const { platform, receipt, productId, packageName } = await req.json().catch(() => ({}));
        if (!platform || !receipt || !productId) {
            return new Response("Missing fields", { status: 400 });
        }

        // --- STUB MODE: godkend ALT (til udvikling) ---
        if (IAP_VERIFY_MODE === "stub") {
            await grantPremium(userId);
            return new Response(JSON.stringify({ valid: true, mode: "stub" }), {
                headers: { "Content-Type": "application/json" },
            });
        }

        // --- PROD MODE: rigtig verifikation ---
        let valid = false;
        if (platform === "ios") {
            const res = await verifyApple(receipt, productId);
            valid = res.valid;
        } else if (platform === "android") {
            if (!packageName) return new Response("Missing packageName", { status: 400 });
            const res = await verifyGoogle(packageName, productId, receipt);
            valid = res.valid;
        } else {
            return new Response("Unknown platform", { status: 400 });
        }

        if (valid) await grantPremium(userId);

        return new Response(JSON.stringify({ valid, mode: "prod" }), {
            headers: { "Content-Type": "application/json" },
        });
    } catch (e) {
        return new Response(JSON.stringify({ valid: false, error: String(e) }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});
