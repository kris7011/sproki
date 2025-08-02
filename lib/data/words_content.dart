/// Komplet dansk alfabet ordliste for sprogterapi
/// STRUKTUR: Vokaler (starter) → Lette konsonanter → Komplekse lyde → Avancerede kombinationer
/// RATIONALE: Pædagogisk progression fra fundamentale byggesten til avancerede udtale-udfordringer

class WordContent {
  final String id;
  final String word;
  final String category;
  final String difficulty;
  final String imagePath;
  final String emoji;
  final List<String> requiredWords; // Progressive unlock dependencies
  final bool isStarterWord; // Altid tilgængelige ord (fundamentale vokaler)

  WordContent({
    required this.id,
    required this.word,
    required this.category,
    required this.difficulty,
    required this.imagePath,
    required this.emoji,
    this.requiredWords = const [],
    this.isStarterWord = false,
  });
}

final List<WordContent> initialWords = [
  // ===== FUNDAMENTALE VOKALER - STARTER KATEGORI =====
  // Disse er altid unlocked da vokaler er byggesten for al dansk udtale
  // Børn lærer vokaler først da de er lettere at producere end konsonanter

  // A-LYDE (Starter vokaler - universelt tilgængelige)
  WordContent(
    id: 'and',
    word: 'and',
    category: 'a-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/and.png',
    emoji: '🦆',
    isStarterWord: true, // Fundamentale vokaler altid tilgængelige
  ),
  WordContent(
    id: 'arm',
    word: 'arm',
    category: 'a-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/arm.png',
    emoji: '💪',
    isStarterWord: true,
  ),
  WordContent(
    id: 'baby',
    word: 'baby',
    category: 'a-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/baby.png',
    emoji: '👶',
    isStarterWord: true,
  ),

  // E-LYDE (Starter vokaler)
  WordContent(
    id: 'elefant',
    word: 'elefant',
    category: 'e-sounds',
    difficulty:
        'medium', // Længere ord kræver mere udviklede motoriske færdigheder
    imagePath: 'assets/images/elefant.png',
    emoji: '🐘',
    isStarterWord: true,
  ),
  WordContent(
    id: 'te',
    word: 'te',
    category: 'e-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/te.png',
    emoji: '☕',
    isStarterWord: true,
  ),
  WordContent(
    id: 'se',
    word: 'se',
    category: 'e-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/se.png',
    emoji: '👀',
    isStarterWord: true,
  ),

  // I-LYDE (Starter vokaler)
  WordContent(
    id: 'is',
    word: 'is',
    category: 'i-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/is.png',
    emoji: '🍦',
    isStarterWord: true,
  ),
  WordContent(
    id: 'tiger',
    word: 'tiger',
    category: 'i-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/tiger.png',
    emoji: '🐅', // Tiger = universelt genkendeligt for børn
    isStarterWord: true,
  ),
  WordContent(
    id: 'dit',
    word: 'dit',
    category: 'i-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/dit.png',
    emoji: '👆', // Pointing finger = dit/your
    isStarterWord: true,
  ),

  // O-LYDE (Starter vokaler)
  WordContent(
    id: 'ord',
    word: 'ord',
    category: 'o-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/ord.png',
    emoji: '📝', // Writing/text = ord/word
    isStarterWord: true,
  ),
  WordContent(
    id: 'bro',
    word: 'bro',
    category: 'o-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/bro.png',
    emoji: '🌉',
    isStarterWord: true,
  ),

  // U-LYDE (Starter vokaler)
  WordContent(
    id: 'ugle',
    word: 'ugle',
    category: 'u-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/ugle.png',
    emoji: '🦉',
    isStarterWord: true,
  ),
  WordContent(
    id: 'bus',
    word: 'bus',
    category: 'u-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/bus.png',
    emoji: '🚌',
    isStarterWord: true,
  ),
  WordContent(
    id: 'hus',
    word: 'hus',
    category: 'u-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/hus.png',
    emoji: '🏠',
    isStarterWord: true,
  ),

  // ===== LETTE KONSONANTER - TIER 1 =====
  // Progression: Vokaler → Simple konsonanter → Komplekse konsonanter
  // Disse låses op når børn mestrer grundvokalerne (evidens-baseret progression)

  // B-LYDE (låses op fra vokal mastery)
  WordContent(
    id: 'bold',
    word: 'bold',
    category: 'b-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/bold.png',
    emoji: '⚽',
    requiredWords: ['and', 'arm'], // Kræver 2 A-lyde mestret først
  ),
  WordContent(
    id: 'bord',
    word: 'bord',
    category: 'b-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/bord.png',
    emoji: '📋', // Clipboard represents table/board
    requiredWords: ['is', 'te'], // Kræver I og E vokal mastery
  ),
  WordContent(
    id: 'bog',
    word: 'bog',
    category: 'b-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/bog.png',
    emoji: '📚',
    requiredWords: ['bold'], // Intern B-lyde progression
  ),
  WordContent(
    id: 'blå',
    word: 'blå',
    category: 'b-sounds',
    difficulty: 'medium', // Konsonant cluster 'bl' er sværere
    imagePath: 'assets/images/blå.png',
    emoji: '🔵',
    requiredWords: ['bord', 'bog'], // Kræver flere B-lyde mestret
  ),

  // D-LYDE
  WordContent(
    id: 'dør',
    word: 'dør',
    category: 'd-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/dør.png',
    emoji: '🚪',
    requiredWords: ['baby', 'elefant'], // Kræver A og E vokal mastery
  ),
  WordContent(
    id: 'dukke',
    word: 'dukke',
    category: 'd-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/dukke.png',
    emoji: '🪆', // Nesting doll
    requiredWords: ['ugle', 'bus'], // Kræver U-lyde mestret
  ),
  WordContent(
    id: 'dans',
    word: 'dans',
    category: 'd-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/dans.png',
    emoji: '💃',
    requiredWords: ['dør', 'dukke'], // Intern D-lyde progression
  ),
  WordContent(
    id: 'drøm',
    word: 'drøm',
    category: 'd-sounds',
    difficulty: 'hard', // 'dr' cluster + ø vokal er avanceret
    imagePath: 'assets/images/drøm.png',
    emoji: '💭', // Dream cloud
    requiredWords: ['dans'], // Kræver solid D-lyde foundation
  ),

  // M-LYDE
  WordContent(
    id: 'mor',
    word: 'mor',
    category: 'm-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/mor.png',
    emoji: '👩', // Mother figure
    requiredWords: ['ord', 'bro'], // Kræver O-lyde mestret
  ),
  WordContent(
    id: 'mælk',
    word: 'mælk',
    category: 'm-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/mælk.png',
    emoji: '🥛',
    requiredWords: ['dit', 'se'], // Kræver I og E lyde
  ),
  WordContent(
    id: 'måne',
    word: 'måne',
    category: 'm-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/måne.png',
    emoji: '🌙',
    requiredWords: ['mor', 'mælk'], // Intern M-lyde progression
  ),
  WordContent(
    id: 'mad',
    word: 'mad',
    category: 'm-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/mad.png',
    emoji: '🍽️',
    requiredWords: ['måne'], // Bygger på M-lyde mastery
  ),

  // N-LYDE
  WordContent(
    id: 'næse',
    word: 'næse',
    category: 'n-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/næse.png',
    emoji: '👃',
    requiredWords: ['hus', 'tiger'], // Kræver U og I lyde
  ),
  WordContent(
    id: 'nat',
    word: 'nat',
    category: 'n-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/nat.png',
    emoji: '🌃', // Night cityscape
    requiredWords: ['bold', 'bog'], // Kræver B-lyde mestret
  ),
  WordContent(
    id: 'nål',
    word: 'nål',
    category: 'n-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/nål.png',
    emoji: '📍', // Pin = nål/needle
    requiredWords: ['næse', 'nat'], // Intern N-lyde progression
  ),
  WordContent(
    id: 'nummer',
    word: 'nummer',
    category: 'n-sounds',
    difficulty: 'medium', // Længere ord med dobbelkonsonant
    imagePath: 'assets/images/nummer.png',
    emoji: '🔢',
    requiredWords: ['nål'], // Avanceret N-lyd
  ),

  // P-LYDE
  WordContent(
    id: 'pige',
    word: 'pige',
    category: 'p-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/pige.png',
    emoji: '👧',
    requiredWords: ['dør', 'dans'], // Kræver D-lyde mestret
  ),
  WordContent(
    id: 'pizza',
    word: 'pizza',
    category: 'p-sounds',
    difficulty: 'medium', // Længere ord med dobbelkonsonant
    imagePath: 'assets/images/pizza.png',
    emoji: '🍕',
    requiredWords: ['mor', 'måne'], // Kræver M-lyde mestret
  ),
  WordContent(
    id: 'papir',
    word: 'papir',
    category: 'p-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/papir.png',
    emoji: '📄',
    requiredWords: ['pige', 'pizza'], // Intern P-lyde progression
  ),
  WordContent(
    id: 'pære',
    word: 'pære',
    category: 'p-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/pære.png',
    emoji: '🍐',
    requiredWords: ['papir'], // Avanceret P-lyd
  ),

  // T-LYDE
  WordContent(
    id: 'tog',
    word: 'tog',
    category: 't-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/tog.png',
    emoji: '🚂',
    requiredWords: ['næse', 'nål'], // Kræver N-lyde mestret
  ),
  WordContent(
    id: 'tand',
    word: 'tand',
    category: 't-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/tand.png',
    emoji: '🦷',
    requiredWords: ['pige', 'papir'], // Kræver P-lyde mestret
  ),
  WordContent(
    id: 'top',
    word: 'top',
    category: 't-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/top.png',
    emoji: '⛰️', // Mountain top
    requiredWords: ['tog', 'tand'], // Intern T-lyde progression
  ),
  WordContent(
    id: 'tre',
    word: 'tre',
    category: 't-sounds',
    difficulty: 'medium', // 'tr' cluster er sværere
    imagePath: 'assets/images/tre.png',
    emoji: '3️⃣',
    requiredWords: ['top'], // Bygger på T-lyde mastery
  ),

  // ===== KOMPLEKSE KONSONANTER - TIER 2 =====
  // Disse inkluderer eksisterende S/R/L/F/V/K/G lyde men nu med opdaterede dependencies
  // Progression fra lette konsonanter til mere udfordrende artikulationer

  // S-LYDE (tidligere starter ord, nu progression fra T-lyde)
  WordContent(
    id: 'sol',
    word: 'sol',
    category: 's-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/sol.png',
    emoji: '☀️',
    requiredWords: [
      'tog',
      'top',
    ], // Nu låses op fra T-lyde i stedet for starter
  ),
  WordContent(
    id: 'sko',
    word: 'sko',
    category: 's-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/sko.png',
    emoji: '👟',
    requiredWords: ['tand'], // Fra T-lyde progression
  ),
  WordContent(
    id: 'mus',
    word: 'mus',
    category: 's-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/mus.png',
    emoji: '🐭',
    requiredWords: ['tre'], // Fra avanceret T-lyd
  ),

  // S-LYDE TIER 1 (opdateret progression)
  WordContent(
    id: 'seb',
    word: 'seb',
    category: 's-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/seb.png',
    emoji: '🍎',
    requiredWords: ['sol', 'sko'], // Intern S-lyde progression
  ),
  WordContent(
    id: 'sort',
    word: 'sort',
    category: 's-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/sort.png',
    emoji: '⚫',
    requiredWords: ['sol', 'mus'],
  ),
  WordContent(
    id: 'syv',
    word: 'syv',
    category: 's-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/syv.png',
    emoji: '7️⃣',
    requiredWords: ['sko', 'mus'],
  ),

  // S-LYDE TIER 2
  WordContent(
    id: 'snak',
    word: 'snak',
    category: 's-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/snak.png',
    emoji: '💬',
    requiredWords: ['seb', 'sort'],
  ),
  WordContent(
    id: 'saks',
    word: 'saks',
    category: 's-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/saks.png',
    emoji: '✂️',
    requiredWords: ['syv', 'sort'],
  ),
  WordContent(
    id: 'seks',
    word: 'seks',
    category: 's-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/seks.png',
    emoji: '6️⃣',
    requiredWords: ['syv'],
  ),

  // S-LYDE TIER 3 (avancerede)
  WordContent(
    id: 'sten',
    word: 'sten',
    category: 's-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/sten.png',
    emoji: '🗿',
    requiredWords: ['snak', 'saks'],
  ),
  WordContent(
    id: 'slange',
    word: 'slange',
    category: 's-sounds',
    difficulty: 'hard', // 'sl' cluster er udfordrende
    imagePath: 'assets/images/slange.png',
    emoji: '🐍',
    requiredWords: ['sten'],
  ),

  // R-LYDE (ofte problematiske - kræver god S-lyde foundation)
  WordContent(
    id: 'rød',
    word: 'rød',
    category: 'r-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/rød.png',
    emoji: '🔴',
    requiredWords: ['seb'], // Låses op fra S-lyde success
  ),
  WordContent(
    id: 'rose',
    word: 'rose',
    category: 'r-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/rose.png',
    emoji: '🌹',
    requiredWords: ['rød'],
  ),
  WordContent(
    id: 'regn',
    word: 'regn',
    category: 'r-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/regn.png',
    emoji: '🌧️',
    requiredWords: ['rose'],
  ),
  WordContent(
    id: 'radio',
    word: 'radio',
    category: 'r-sounds',
    difficulty: 'hard',
    imagePath: 'assets/images/radio.png',
    emoji: '📻',
    requiredWords: ['regn'],
  ),

  // L-LYDE (laterale lyde - kræver specifik tungplacering)
  WordContent(
    id: 'lys',
    word: 'lys',
    category: 'l-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/lys.png',
    emoji: '💡',
    requiredWords: ['rød'], // Låses op fra R-lyde progression
  ),
  WordContent(
    id: 'løve',
    word: 'løve',
    category: 'l-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/løve.png',
    emoji: '🦁',
    requiredWords: ['lys'],
  ),
  WordContent(
    id: 'lukke',
    word: 'lukke',
    category: 'l-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/lukke.png',
    emoji: '🔒',
    requiredWords: ['løve'],
  ),

  // F-LYDE (frikative lyde)
  WordContent(
    id: 'fire',
    word: 'fire',
    category: 'f-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/fire.png',
    emoji: '4️⃣',
    requiredWords: ['lys'], // Parallelt med L-lyde
  ),
  WordContent(
    id: 'fugl',
    word: 'fugl',
    category: 'f-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/fugl.png',
    emoji: '🐦',
    requiredWords: ['fire'],
  ),
  WordContent(
    id: 'flag',
    word: 'flag',
    category: 'f-sounds',
    difficulty: 'medium', // 'fl' cluster
    imagePath: 'assets/images/flag.png',
    emoji: '🏁',
    requiredWords: ['fugl'],
  ),
  WordContent(
    id: 'frugt',
    word: 'frugt',
    category: 'f-sounds',
    difficulty: 'medium', // 'fr' cluster
    imagePath: 'assets/images/frugt.png',
    emoji: '🍇',
    requiredWords: ['flag'],
  ),

  // V-LYDE (ofte forvekslet med F-lyde)
  WordContent(
    id: 'vand',
    word: 'vand',
    category: 'v-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/vand.png',
    emoji: '💧',
    requiredWords: ['fire'], // Parallelt med F-lyde for sammenligning
  ),
  WordContent(
    id: 'bil',
    word: 'bil',
    category: 'v-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/bil.png',
    emoji: '🚗',
    requiredWords: ['vand'],
  ),
  WordContent(
    id: 'vin',
    word: 'vin',
    category: 'v-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/vin.png',
    emoji: '🍷',
    requiredWords: ['bil'],
  ),
  WordContent(
    id: 'vejr',
    word: 'vejr',
    category: 'v-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/vejr.png',
    emoji: '🌤️',
    requiredWords: ['vin'],
  ),

  // K-LYDE (hårde konsonanter)
  WordContent(
    id: 'ko',
    word: 'ko',
    category: 'k-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/ko.png',
    emoji: '🐄',
    requiredWords: ['vand'], // Fra V-lyde progression
  ),
  WordContent(
    id: 'kage',
    word: 'kage',
    category: 'k-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/kage.png',
    emoji: '🎂',
    requiredWords: ['ko'],
  ),
  WordContent(
    id: 'kaffe',
    word: 'kaffe',
    category: 'k-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/kaffe.png',
    emoji: '☕',
    requiredWords: ['kage'],
  ),
  WordContent(
    id: 'kylling',
    word: 'kylling',
    category: 'k-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/kylling.png',
    emoji: '🐔',
    requiredWords: ['kaffe'],
  ),

  // G-LYDE (stemte velære plosiver)
  WordContent(
    id: 'gul',
    word: 'gul',
    category: 'g-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/gul.png',
    emoji: '🟡',
    requiredWords: ['ko'], // Parallelt med K-lyde for sammenligning
  ),
  WordContent(
    id: 'gave',
    word: 'gave',
    category: 'g-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/gave.png',
    emoji: '🎁',
    requiredWords: ['gul'],
  ),
  WordContent(
    id: 'grøn',
    word: 'grøn',
    category: 'g-sounds',
    difficulty: 'medium', // 'gr' cluster
    imagePath: 'assets/images/grøn.png',
    emoji: '🟢',
    requiredWords: ['gave'],
  ),
  WordContent(
    id: 'glas',
    word: 'glas',
    category: 'g-sounds',
    difficulty: 'medium', // 'gl' cluster
    imagePath: 'assets/images/glas.png',
    emoji: '🥛',
    requiredWords: ['grøn'],
  ),

  // ===== DANSKE SPECIALVOKALER - TIER 3 =====
  // Æ, Ø, Å er unikke for dansk og kræver specifik artikulation

  // Æ-LYDE (unik dansk vokal)
  WordContent(
    id: 'æble',
    word: 'æble',
    category: 'æ-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/æble.png',
    emoji: '🍎',
    requiredWords: ['lukke'], // Fra L-lyde mastery
  ),
  WordContent(
    id: 'læge',
    word: 'læge',
    category: 'æ-sounds',
    difficulty: 'medium',
    imagePath: 'assets/images/læge.png',
    emoji: '👨‍⚕️', // Doctor
    requiredWords: ['æble'],
  ),
  WordContent(
    id: 'træ',
    word: 'træ',
    category: 'æ-sounds',
    difficulty: 'medium', // 'tr' cluster + æ
    imagePath: 'assets/images/træ.png',
    emoji: '🌳',
    requiredWords: ['læge'],
  ),

  // Ø-LYDE (rundede vokaler)
  WordContent(
    id: 'ørn',
    word: 'ørn',
    category: 'ø-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/ørn.png',
    emoji: '🦅', // Eagle
    requiredWords: ['frugt'], // Fra F-lyde mastery
  ),
  WordContent(
    id: 'ø',
    word: 'ø',
    category: 'ø-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/ø.png',
    emoji: '🏝️', // Island
    requiredWords: ['ørn'],
  ),
  WordContent(
    id: 'grød',
    word: 'grød',
    category: 'ø-sounds',
    difficulty: 'medium', // 'gr' cluster + ø
    imagePath: 'assets/images/grød.png',
    emoji: '🥣', // Bowl of porridge
    requiredWords: ['ø'],
  ),

  // Å-LYDE (bagre rundede vokaler)
  WordContent(
    id: 'åben',
    word: 'åben',
    category: 'å-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/åben.png',
    emoji: '📂', // Open folder
    requiredWords: ['vejr'], // Fra V-lyde mastery
  ),
  WordContent(
    id: 'kål',
    word: 'kål',
    category: 'å-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/kål.png',
    emoji: '🥬', // Cabbage
    requiredWords: ['åben'],
  ),
  WordContent(
    id: 'år',
    word: 'år',
    category: 'å-sounds',
    difficulty: 'easy',
    imagePath: 'assets/images/år.png',
    emoji: '📅', // Calendar = year
    requiredWords: ['kål'],
  ),

  // ===== KATEGORISEREDE TEMATISKE ORD - TIER 4 =====
  // Disse låses op sent da de kræver bred fonologisk kompetence

  // DYR KATEGORI (kræver L-lyde mastery da dyr ofte har komplekse lyde)
  WordContent(
    id: 'kat',
    word: 'kat',
    category: 'animals',
    difficulty: 'easy',
    imagePath: 'assets/images/kat.png',
    emoji: '🐱',
    requiredWords: ['lukke'], // Fra L-lyde progression
  ),
  WordContent(
    id: 'hund',
    word: 'hund',
    category: 'animals',
    difficulty: 'easy',
    imagePath: 'assets/images/hund.png',
    emoji: '🐶',
    requiredWords: ['kat'],
  ),
  WordContent(
    id: 'fisk',
    word: 'fisk',
    category: 'animals',
    difficulty: 'medium',
    imagePath: 'assets/images/fisk.png',
    emoji: '🐟',
    requiredWords: ['hund'],
  ),

  // MAD KATEGORI (dagligdags ord - kræver bred fonologisk base)
  WordContent(
    id: 'brød',
    word: 'brød',
    category: 'food',
    difficulty: 'medium', // 'br' cluster + ø
    imagePath: 'assets/images/brød.png',
    emoji: '🍞',
    requiredWords: ['fisk'], // Fra dyr progression
  ),
  WordContent(
    id: 'ost',
    word: 'ost',
    category: 'food',
    difficulty: 'easy',
    imagePath: 'assets/images/ost.png',
    emoji: '🧀',
    requiredWords: ['brød'],
  ),

  // ===== AVANCEREDE KOMBINATIONER - TIER 5 =====
  // Mest udfordrende ord der kræver mastery af multiple lydkategorier
  // Disse ord tester fonologisk bevidsthed og kompleks artikulatorisk kontrol
  WordContent(
    id: 'frost',
    word: 'frost',
    category: 'advanced',
    difficulty: 'hard',
    imagePath: 'assets/images/frost.png',
    emoji: '❄️',
    requiredWords: [
      'frugt',
      'grøn',
    ], // Kræver F og G mastery (fr + st clusters)
  ),
  WordContent(
    id: 'skrig',
    word: 'skrig',
    category: 'advanced',
    difficulty: 'hard',
    imagePath: 'assets/images/skrig.png',
    emoji: '😱',
    requiredWords: ['slange', 'glas'], // S + G kombination (sk + gr clusters)
  ),
  WordContent(
    id: 'storm',
    word: 'storm',
    category: 'advanced',
    difficulty: 'hard',
    imagePath: 'assets/images/storm.png',
    emoji: '⛈️',
    requiredWords: ['sten', 'træ'], // St + rm clusters med specialvokal
  ),
  WordContent(
    id: 'spring',
    word: 'spring',
    category: 'advanced',
    difficulty: 'hard',
    imagePath: 'assets/images/spring.png',
    emoji: '🌸', // Spring blossom
    requiredWords: ['frost', 'skrig'], // Multiple cluster mastery required
  ),
];
