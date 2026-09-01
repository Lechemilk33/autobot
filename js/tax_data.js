// Verified federal tax data used by ShiftMath.
//
// Sources (verified 2026-09-01):
// - Tips deduction (IRC §224): IRS "What the No Tax on Tips deduction means for you"
//   https://www.irs.gov/newsroom/what-the-no-tax-on-tips-deduction-means-for-you
// - Overtime deduction (IRC §225): IRS FS-2026-13 (Aug 2026 FAQ)
//   https://www.irs.gov/pub/taxpros/fs-2026-13.pdf
// - Phase-out: IRS https://www.irs.gov/newsroom/one-big-beautiful-bill-how-to-take-advantage-of-no-tax-on-tips-and-overtime
//   ($100 reduction per $1,000 of MAGI over $150k / $300k joint; implemented as
//   10% of the excess per the Schedule 1-A worksheet)
// - 2026 brackets & standard deduction: Rev. Proc. 2025-32
//   https://www.irs.gov/pub/irs-drop/rp-25-32.pdf
// - 2025 brackets: Rev. Proc. 2024-40 (std deduction post-OBBBA):
//   https://taxfoundation.org/data/all/federal/2025-tax-brackets/
// - Tipped occupation list: TD 10044, 91 FR 19026 (26 CFR §1.224-1, Table 1) — 71 occupations
//   https://www.federalregister.gov/documents/2026/04/13/2026-07104/occupations-that-customarily-and-regularly-received-tips-definition-of-qualified-tips

export const OBBBA = {
  effectiveYears: [2025, 2026, 2027, 2028],
  tips: {
    cap: 25000, // per return — does NOT double for joint filers
    selfEmployedNetIncomeLimit: true,
  },
  overtime: {
    capSingle: 12500,
    capJoint: 25000,
  },
  phaseout: {
    thresholdSingle: 150000,
    thresholdJoint: 300000,
    ratePerDollar: 0.10, // $100 per $1,000 of MAGI excess
  },
};

// brackets: ascending, upTo = top of bracket in taxable income dollars.
export const YEARS = {
  2026: {
    standardDeduction: { single: 16100, mfj: 32200, hoh: 24150 },
    brackets: {
      single: [
        { rate: 0.10, upTo: 12400 },
        { rate: 0.12, upTo: 50400 },
        { rate: 0.22, upTo: 105700 },
        { rate: 0.24, upTo: 201775 },
        { rate: 0.32, upTo: 256225 },
        { rate: 0.35, upTo: 640600 },
        { rate: 0.37, upTo: Infinity },
      ],
      mfj: [
        { rate: 0.10, upTo: 24800 },
        { rate: 0.12, upTo: 100800 },
        { rate: 0.22, upTo: 211400 },
        { rate: 0.24, upTo: 403550 },
        { rate: 0.32, upTo: 512450 },
        { rate: 0.35, upTo: 768700 },
        { rate: 0.37, upTo: Infinity },
      ],
      hoh: [
        { rate: 0.10, upTo: 17700 },
        { rate: 0.12, upTo: 67450 },
        { rate: 0.22, upTo: 105700 },
        { rate: 0.24, upTo: 201775 },
        { rate: 0.32, upTo: 256225 },
        { rate: 0.35, upTo: 640600 },
        { rate: 0.37, upTo: Infinity },
      ],
    },
  },
  2025: {
    standardDeduction: { single: 15750, mfj: 31500, hoh: 23625 },
    brackets: {
      single: [
        { rate: 0.10, upTo: 11925 },
        { rate: 0.12, upTo: 48475 },
        { rate: 0.22, upTo: 103350 },
        { rate: 0.24, upTo: 197300 },
        { rate: 0.32, upTo: 250525 },
        { rate: 0.35, upTo: 626350 },
        { rate: 0.37, upTo: Infinity },
      ],
      mfj: [
        { rate: 0.10, upTo: 23850 },
        { rate: 0.12, upTo: 96950 },
        { rate: 0.22, upTo: 206700 },
        { rate: 0.24, upTo: 394600 },
        { rate: 0.32, upTo: 501050 },
        { rate: 0.35, upTo: 751600 },
        { rate: 0.37, upTo: Infinity },
      ],
      hoh: [
        { rate: 0.10, upTo: 17000 },
        { rate: 0.12, upTo: 64850 },
        { rate: 0.22, upTo: 103350 },
        { rate: 0.24, upTo: 197300 },
        { rate: 0.32, upTo: 250500 },
        { rate: 0.35, upTo: 626350 },
        { rate: 0.37, upTo: Infinity },
      ],
    },
  },
};

// Treasury Tipped Occupation Codes — TD 10044 final rule, 71 occupations.
export const TTOC = {
  "100": { category: "Beverage & Food Service", occupations: {
    "101": "Bartenders",
    "102": "Wait staff",
    "103": "Food servers, non-restaurant",
    "104": "Dining room and cafeteria attendants and bartender helpers",
    "105": "Chefs and cooks",
    "106": "Food preparation workers",
    "107": "Fast food and counter workers",
    "108": "Dishwashers",
    "109": "Host staff, restaurant, lounge, and coffee shop",
    "110": "Bakers",
  }},
  "200": { category: "Entertainment & Events", occupations: {
    "201": "Gambling dealers",
    "202": "Gambling change persons and booth cashiers",
    "203": "Gambling cage workers",
    "204": "Gambling and sports book writers and runners",
    "205": "Dancers",
    "206": "Musicians and singers",
    "207": "Disc jockeys, except radio",
    "208": "Entertainers and performers",
    "209": "Digital content creators",
    "210": "Ushers, lobby attendants, and ticket takers",
    "211": "Locker room, coatroom, and dressing room attendants",
  }},
  "300": { category: "Hospitality & Guest Services", occupations: {
    "301": "Baggage porters and bellhops",
    "302": "Concierges",
    "303": "Hotel, motel, and resort desk clerks",
    "304": "Maids and housekeeping cleaners",
  }},
  "400": { category: "Home Services", occupations: {
    "401": "Home maintenance and repair workers",
    "402": "Home landscaping and groundskeeping workers",
    "403": "Home electricians",
    "404": "Home plumbers",
    "405": "Home heating and air conditioning mechanics and installers",
    "406": "Home appliance installers and repairers",
    "407": "Home cleaning service workers",
    "408": "Locksmiths",
    "409": "Roadside assistance workers",
  }},
  "500": { category: "Personal Services", occupations: {
    "501": "Personal care and service workers",
    "502": "Private event planners",
    "503": "Private event and portrait photographers",
    "504": "Private event videographers",
    "505": "Event officiants",
    "506": "Pet caretakers and show animal caretakers",
    "507": "Tutors",
    "508": "Nannies and babysitters",
    "509": "Visual artists",
    "510": "Floral designers",
  }},
  "600": { category: "Personal Appearance & Wellness", occupations: {
    "601": "Skincare specialists",
    "602": "Massage therapists",
    "603": "Barbers, hairdressers, hairstylists, and cosmetologists",
    "604": "Shampooers",
    "605": "Manicurists and pedicurists",
    "606": "Eyebrow threading and waxing technicians",
    "607": "Makeup artists",
    "608": "Exercise trainers and group fitness instructors",
    "609": "Tattoo artists and piercers",
    "610": "Tailors",
    "611": "Shoe and leather workers and repairers",
  }},
  "700": { category: "Recreation & Instruction", occupations: {
    "701": "Golf caddies",
    "702": "Self-enrichment teachers",
    "703": "Recreational and tour pilots",
    "704": "Tour guides and escorts",
    "705": "Travel guides",
    "706": "Sports and recreation instructors",
  }},
  "800": { category: "Transportation & Delivery", occupations: {
    "801": "Parking and valet attendants",
    "802": "Taxi and rideshare drivers and chauffeurs",
    "803": "Shuttle drivers",
    "804": "Goods delivery people",
    "805": "Personal vehicle and equipment cleaners",
    "806": "Private and charter bus drivers",
    "807": "Water taxi operators and charter boat workers",
    "808": "Rickshaw, pedicab, and carriage drivers",
    "809": "Home movers",
    "810": "Gas pump attendants",
  }},
};
