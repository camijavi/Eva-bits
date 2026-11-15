import '../languages/app_strings.dart';

class CropPestWarning {
  final String pestName;
  final String scientificName;
  final String riskLevel; // 'high', 'moderate'
  final String climateTrigger;
  final String symptomsAndImpact;
  final String preventionAction;
  final String sourceCitation;

  const CropPestWarning({
    required this.pestName,
    required this.scientificName,
    required this.riskLevel,
    required this.climateTrigger,
    required this.symptomsAndImpact,
    required this.preventionAction,
    required this.sourceCitation,
  });
}

class NaturalPhenomenonWarning {
  final String phenomenonName;
  final String severity; // 'danger', 'warning', 'info'
  final String satelliteSource;
  final String description;
  final String preventionMeasure;
  final String citation;

  const NaturalPhenomenonWarning({
    required this.phenomenonName,
    required this.severity,
    required this.satelliteSource,
    required this.description,
    required this.preventionMeasure,
    required this.citation,
  });
}

class IrrigationSystemOption {
  final String systemName;
  final String efficiencyPct;
  final String bestForSoil;
  final String description;
  final String nasaIntegrationNote;
  final bool isRecommendedForCurrentSoil;

  const IrrigationSystemOption({
    required this.systemName,
    required this.efficiencyPct,
    required this.bestForSoil,
    required this.description,
    required this.nasaIntegrationNote,
    required this.isRecommendedForCurrentSoil,
  });
}

class WeeklyProjectionPhase {
  final int weekNumber;
  final String dateRangeLabel;
  final String title;
  final String expectedMetrics;
  final String recommendedAction;

  const WeeklyProjectionPhase({
    required this.weekNumber,
    required this.dateRangeLabel,
    required this.title,
    required this.expectedMetrics,
    required this.recommendedAction,
  });
}

class ThreeWeekProjection {
  final String fullDateRange;
  final List<WeeklyProjectionPhase> phases;
  final String longTermClimateNote;
  final String weeklyCheckpointTitle;
  final String weeklyCheckpointPeriod;
  final String weeklyCheckpointSummary;
  final List<String> weeklyChangesDetected;

  const ThreeWeekProjection({
    required this.fullDateRange,
    required this.phases,
    required this.longTermClimateNote,
    required this.weeklyCheckpointTitle,
    required this.weeklyCheckpointPeriod,
    required this.weeklyCheckpointSummary,
    required this.weeklyChangesDetected,
  });
}

class EveKnowledgeBase {
  static String _formatShortDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d/$m/$y';
  }

  static String getSoilScientificConcept(String soilType, {bool? isSpanish}) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    final lower = soilType.toLowerCase();

    if (lower.contains('aren') || lower.contains('sand')) {
      return es
          ? 'Suelo Arenoso: Evita encharcamientos porque drena el agua con rapidez, pero pierde nutrientes con mayor facilidad por filtración profunda.'
          : 'Sandy Soil: Prevents waterlogging by draining water rapidly, but loses nutrients more easily through deep filtration.';
    }
    if (lower.contains('lim') || lower.contains('silt')) {
      return es
          ? 'Suelo Limoso: Retiene con facilidad la humedad y los nutrientes dejando una textura suave y buen drenaje (muy fértil), pero tiende a compactarse si queda descubierto en terrenos inclinados.'
          : 'Silt Soil: Easily retains moisture and nutrients with a smooth texture and good drainage (highly fertile), but compacts easily if left bare on sloped terrain.';
    }
    if (lower.contains('arcill') || lower.contains('clay')) {
      return es
          ? 'Suelo Arcilloso: Retiene sin dificultad el agua y los nutrientes, pero drena lento, volviéndose pegajoso y pesado, dificultando que raíces sensibles penetren y crezcan.'
          : 'Clay Soil: Easily retains water and nutrients, but drains slowly, becoming sticky and heavy, making root penetration difficult for sensitive plants.';
    }
    return es
        ? 'Suelo Franco: Combinación balanceada de arena, limo y arcilla considerada óptima para cultivar; posee drenaje adecuado, retiene nutrientes y humedad, y ofrece textura suelta para el desarrollo radicular.'
        : 'Loam Soil: Balanced combination of sand, silt, and clay considered ideal for farming; offers proper drainage, retains nutrients and moisture, and provides a loose texture for root expansion.';
  }

  /// Evaluates Natural Phenomena and Compound Climate Events
  static List<NaturalPhenomenonWarning> evaluateNaturalPhenomena({
    required double tempC,
    required double rain7dMm,
    required double soilMoisture,
    required double solarMj,
    required String soilType,
    required String crop,
    bool? isSpanish,
  }) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    final List<NaturalPhenomenonWarning> warnings = [];
    final isSiltOrClay = soilType.toLowerCase().contains('lim') ||
        soilType.toLowerCase().contains('arcill') ||
        soilType.toLowerCase().contains('silt') ||
        soilType.toLowerCase().contains('clay');

    // 1. Compound Climate Event: Heatwave + Drought
    final bool isCompoundRisk =
        (soilMoisture < 0.45 && tempC >= 26.5) || rain7dMm < 5.0;
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Sequía y Olas de Calor Simultáneas'
            : 'Simultaneous Drought & Heatwaves',
        severity: isCompoundRisk ? 'danger' : 'warning',
        satelliteSource: '',
        description: es
            ? 'La ocurrencia simultánea de olas de calor y falta de lluvias refuerza el estrés hídrico del suelo y puede duplicar el riesgo de pérdida en la cosecha si no se protege la humedad radicular.'
            : 'Simultaneous heatwaves and low rainfall amplify soil water stress and can double crop loss risks if root-zone moisture is not protected.',
        preventionMeasure: es
            ? 'Aplicar cobertura vegetal (mulch) para conservar la humedad de la raíz y rotar con leguminosas tolerantes.'
            : 'Apply organic mulch to conserve root-zone moisture and rotate with drought-tolerant legumes.',
        citation: '',
      ),
    );

    // 2. Extreme 3-Day Precipitation, Floods & Hurricanes
    final bool isFloodRisk = rain7dMm > 25.0 || soilMoisture > 0.72;
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Precipitaciones Intensas e Inundaciones'
            : 'Intense Precipitation & Flood Risk',
        severity: isFloodRisk ? 'danger' : 'info',
        satelliteSource: '',
        description: es
            ? 'Las lluvias intensas durante varios días seguidos pueden causar inundaciones repentinas, erosión superficial del suelo y pérdida directa de siembras.'
            : 'Intense multi-day rainfall events can cause flash floods, surface soil erosion, and direct planting loss.',
        preventionMeasure: es
            ? 'Trazar canales de evacuación pluvial en los bordes del lote y mantener barreras vivas para frenar la escorrentía superficial.'
            : 'Build rainwater drainage channels along parcel borders and maintain living barriers to slow surface runoff.',
        citation: '',
      ),
    );

    // 3. Landslides & Slope Compaction
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Deslizamientos y Compactación en Ladera'
            : 'Landslides & Slope Soil Compaction',
        severity: (isFloodRisk && isSiltOrClay) ? 'warning' : 'info',
        satelliteSource: '',
        description: es
            ? 'En suelos saturados o descubiertos en terrenos inclinados, el exceso de agua arrastra nutrientes y el impacto directo de la lluvia compacta la capa superficial.'
            : 'In saturated or bare soils on sloped terrain, excess water washes away nutrients and raindrop impact compacts the surface layer.',
        preventionMeasure: es
            ? 'Evitar dejar el suelo descubierto en laderas; sembrar en curvas a nivel y mantener rastrojos o cultivos de cobertura.'
            : 'Never leave sloped soil bare; plant along contour lines and maintain crop residue or cover crops.',
        citation: '',
      ),
    );

    // 4. Long-term Thermal Adaptation
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Adaptación Térmica del Cultivo'
            : 'Crop Thermal Adaptation',
        severity: 'info',
        satelliteSource: '',
        description: es
            ? 'El aumento gradual de las temperaturas reduce el rendimiento en cultivos sensibles al calor como el maíz, mientras que rotaciones estratégicas ayudan a estabilizar la producción.'
            : 'Gradually rising temperatures reduce yields in heat-sensitive crops like maize, whereas strategic rotations help stabilize farm output.',
        preventionMeasure: es
            ? 'Diversificar la rotación del lote alternando gramíneas con leguminosas fijadoras de nitrógeno y variedades de ciclo corto.'
            : 'Diversify parcel rotation by alternating grasses with nitrogen-fixing legumes and short-cycle varieties.',
        citation: '',
      ),
    );

    return warnings;
  }

  /// Returns crop-specific pest & disease warnings grounded in the Biotech PDF
  static List<CropPestWarning> getPestWarningsForCrop({
    required String crop,
    required double tempC,
    required double rain7dMm,
    required double soilMoisture,
    required String soilType,
    bool? isSpanish,
  }) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    final lower = crop.toLowerCase().trim();
    final isHumid = soilMoisture >= 0.55 || rain7dMm >= 10.0;
    final isDryWarm = soilMoisture < 0.50 || tempC >= 26.0;
    final isSandy = soilType.toLowerCase().contains('aren') ||
        soilType.toLowerCase().contains('sand');

    // 1. MAÍZ / CORN (Jorge 4K, s.f.; Vilela, 2026)
    if (lower.contains('maíz') || lower.contains('maiz') || lower.contains('corn')) {
      return [
        CropPestWarning(
          pestName: es ? 'Gusano Cogollero' : 'Fall Armyworm (Gusano Cogollero)',
          scientificName: 'Spodoptera frugiperda',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Alta reproducción, adaptación y rápida dispersión en el lote'
              : 'High reproduction, adaptation, and rapid dispersal across plots',
          symptomsAndImpact: es
              ? 'Es la plaga más peligrosa y destructiva del maíz; coloniza con rapidez el cogollo y follaje destruyendo la capacidad fotosintética.'
              : 'The most dangerous and destructive maize pest; rapidly colonizes the whorl and foliage, destroying photosynthetic capacity.',
          preventionAction: es
              ? 'Monitorear cogollos semanalmente, eliminar malezas hospederas y romper el corredor biológico rotando con frijol o soya.'
              : 'Inspect whorls weekly, remove host weeds, and break biological corridors by rotating with beans or soybeans.',
          sourceCitation: 'Vilela (2026); Jorge 4K (s.f.)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Barrenador del Tallo y Gusano de la Mazorca'
              : 'Stalk Borer & Corn Earworm',
          scientificName: 'Género Diatraea / Helicoverpa zea',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Etapas vegetativas y floración/llenado de mazorca'
              : 'Vegetative stages and ear flowering/grain filling',
          symptomsAndImpact: es
              ? 'Diatraea daña la estructura interna del tallo (casi invisible al inicio) reduciendo el rendimiento; el gusano de la mazorca ataca directamente el fruto afectando el producto comercial final.'
              : 'Diatraea damages internal stalk structure (nearly invisible early on) reducing yield; the earworm attacks the cob directly, hurting final commercial quality.',
          preventionAction: es
              ? 'Incorporar rastrojos post-cosecha para eliminar pupas invernantes y usar trampas de feromonas durante la emisión de estigmas.'
              : 'Incorporate post-harvest residue to eliminate overwintering pupae and deploy pheromone traps during silking.',
          sourceCitation: 'Vilela (2026)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Tizón Foliar y Roya Común'
              : 'Northern Corn Leaf Blight & Common Rust',
          scientificName: 'Exserohilum turcicum / Puccinia sorghi',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Climas húmedos y temperaturas moderadas (Humedad actual: ${(soilMoisture * 100).toInt()}%)'
              : 'Humid climates and moderate temperatures (Current moisture: ${(soilMoisture * 100).toInt()}%)',
          symptomsAndImpact: es
              ? 'Hongos foliares que producen lesiones necróticas y pústulas en las hojas, afectando directamente el llenado y rendimiento del grano de maíz.'
              : 'Foliar fungi causing necrotic lesions and pustules on leaves, directly impacting grain filling and maize yield.',
          preventionAction: es
              ? 'Evitar exceso de humedad foliar, mejorar la ventilación entre surcos y rotar cultivos para reducir el inóculo fúngico.'
              : 'Avoid excess foliar moisture, improve row ventilation, and rotate crops to reduce fungal inoculum.',
          sourceCitation: 'Vilela (2026)',
        ),
      ];
    }

    // 2. CAFÉ / COFFEE (Porres y Cuxil, 2024)
    if (lower.contains('café') || lower.contains('cafe') || lower.contains('coffee')) {
      return [
        CropPestWarning(
          pestName: es ? 'Broca del Café' : 'Coffee Berry Borer (Broca)',
          scientificName: 'Hypothenemus hampei',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Desarrollo de cerezas de café en el lote'
              : 'Coffee cherry development on the parcel',
          symptomsAndImpact: es
              ? 'Gorgojo no visible a simple vista que cumple todo su ciclo de vida dentro de las cerezas del café, provocando caída prematura de frutos y deterioro severo del grano.'
              : 'Microscopic beetle that completes its entire life cycle inside coffee cherries, causing premature fruit drop and severe bean quality loss.',
          preventionAction: es
              ? 'Realizar pepena y repela rigurosa de frutos caídos/maduros e instalar trampas con atrayente alcohólico tras las primeras lluvias.'
              : 'Perform strict sanitation harvesting of fallen/ripe berries and install alcohol-attractant traps after initial rains.',
          sourceCitation: 'Porres y Cuxil (2024)',
        ),
        CropPestWarning(
          pestName: es ? 'Araña Roja del Café' : 'Coffee Red Spider Mite',
          scientificName: 'Oligonychus yothersi',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Períodos secos y cálidos (Temperatura actual: ${tempC.toStringAsFixed(1)} °C)'
              : 'Dry and warm periods (Current temp: ${tempC.toStringAsFixed(1)} °C)',
          symptomsAndImpact: es
              ? 'Provoca manchas amarillas que se necrosan y defoliación severa, causando hasta el 30% de pérdida de rendimiento del cultivo.'
              : 'Causes yellow spots that turn necrotic and severe defoliation, leading to up to 30% crop yield loss.',
          preventionAction: es
              ? 'Mantener sombra regulada en el cafetal y aplicar riegos de auxilio en época seca para reducir el polvo foliar.'
              : 'Maintain regulated shade in the coffee plot and apply supplemental irrigation during dry spells.',
          sourceCitation: 'Porres y Cuxil (2024)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Roya Amarilla y Minador de la Hoja'
              : 'Coffee Leaf Rust & Leaf Miner',
          scientificName: 'Hemileia vastatrix / Leucoptera coffeella',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Humedad ambiental y sombrío mal ventilado'
              : 'Ambient humidity and poorly ventilated shade',
          symptomsAndImpact: es
              ? 'La roya genera manchas amarillas en hojas y afecta los granos; el minador crea galerías blancas internas que reducen la capacidad de fotosíntesis.'
              : 'Rust creates yellow leaf lesions affecting beans; the leaf miner tunnels white galleries inside leaves, reducing photosynthesis.',
          preventionAction: es
              ? 'Equilibrar la fertilización potásico-nitrogenada y podar para optimizar la entrada de radiación solar.'
              : 'Balance potassium-nitrogen nutrition and prune to optimize solar radiation penetration.',
          sourceCitation: 'Porres y Cuxil (2024)',
        ),
      ];
    }

    // 3. FRIJOL / BEANS
    if (lower.contains('frijol') || lower.contains('bean')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Mosca Blanca (Vector del Mosaico Dorado)'
              : 'Whitefly (Golden Mosaic Virus Vector)',
          scientificName: 'Bemisia tabaci',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Temperaturas cálidas y periodos secos'
              : 'Warm temperatures and dry spells',
          symptomsAndImpact: es
              ? 'Consume la savia debilitando la planta y transmite el virus del mosaico dorado del frijol, causando amarillamiento y deformación.'
              : 'Sucks sap weakening the plant and transmits Bean Golden Mosaic Virus, causing yellowing and stunting.',
          preventionAction: es
              ? 'Instalar trampas adhesivas amarillas en los linderos y evitar colindancia inmediata con solanáceas o cucurbitáceas infestadas.'
              : 'Place yellow sticky traps along borders and avoid direct adjacency with infested solanaceous or cucurbit crops.',
          sourceCitation: 'Investigación Biotecnológica Eva-Bits (2026)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Pulgones (Fumagina) y Picudo del Frijol'
              : 'Aphids (Sooty Mold) & Bean Weevil',
          scientificName: 'Aphididae / Apion godmani',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Brotación vegetativa y formación de vainas/semillas'
              : 'Vegetative sprouting and pod/seed formation',
          symptomsAndImpact: es
              ? 'Los pulgones transmiten enfermedades virales, agotan la savia y excretan melaza que desarrolla el hongo fumagina; el picudo ataca directamente vainas y semillas reduciendo la calidad del grano.'
              : 'Aphids transmit viral diseases, deplete sap, and excrete honeydew fostering sooty mold; the bean weevil directly attacks pods and seeds.',
          preventionAction: es
              ? 'Monitorear el envés de las hojas y realizar control biológico temprano durante la floración y formación de vainas.'
              : 'Inspect leaf undersides and apply early biological control during flowering and pod formation.',
          sourceCitation: 'Investigación Biotecnológica Eva-Bits (2026)',
        ),
      ];
    }

    // 4. MELÓN / MELON (Cañizo, s.f.; Dubón, 2006)
    if (lower.contains('melón') || lower.contains('melon')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Melera o Mangla (Piojillos / Pulgones)'
              : 'Melera / Mangla (Melon Aphids)',
          scientificName: 'Aphis (Doralis) frangulae Koch / Aphis gossypii',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Reproducción partenogenética rápida sin necesidad de fecundación'
              : 'Rapid parthenogenetic reproduction without fertilization',
          symptomsAndImpact: es
              ? 'Debilita y agota por completo las matas de melón y sandía; al no necesitar fecundación se esparce rápidamente en toda la parcela.'
              : 'Weakens and completely exhausts melon and watermelon vines; spreads rapidly across the parcel without needing fertilization.',
          preventionAction: es
              ? 'Identificación temprana en brotes tiernos y eliminación inmediata de focos iniciales.'
              : 'Early identification on tender shoots and immediate removal of initial infestation hotspots.',
          sourceCitation: 'Cañizo (s.f.)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Arañuela o Socarrina y Lagarta (Vacanita)'
              : 'Spider Mite (Socarrina) & Loopers (Vacanita)',
          scientificName: 'Tetranychidae / Lepidoptera',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Veranos secos y temperaturas elevadas'
              : 'Dry summers and elevated temperatures',
          symptomsAndImpact: es
              ? 'La arañuela se multiplica en el envés de las hojas consumiendo su jugo hasta secarlas sin razón aparente; la lagarta destruye el follaje si no se detecta a tiempo.'
              : 'Mites multiply on leaf undersides sucking plant juices until leaves dry out; loopers destroy foliage if not detected early.',
          preventionAction: es
              ? 'Mantener humedad uniforme mediante riego por goteo y revisar el envés foliar con lupa.'
              : 'Maintain uniform moisture via drip irrigation and inspect leaf undersides with a hand lens.',
          sourceCitation: 'Cañizo (s.f.)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Mosca Blanca (Bemisia) y Complejo de Gusanos Soldados'
              : 'Whitefly (Bemisia) & Armyworm Complex',
          scientificName: 'Bemisia / Spodoptera exigua, S. albula, S. frugiperda',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Valles cálidos y presencia de hortalizas colindantes'
              : 'Warm valleys and adjacent vegetable plots',
          symptomsAndImpact: es
              ? 'Bemisia es el género de Aleyrodidae más dañino en melón y hortalizas; junto con las tres especies de gusanos soldados ocasionan pérdidas severas.'
              : 'Bemisia is the most damaging whitefly genus in melon and vegetables; alongside the three armyworm species, it causes severe yield losses.',
          preventionAction: es
              ? 'Establecer barreras vivas de gramíneas altas y rotar fuera de cucurbitáceas.'
              : 'Establish tall grass living barriers and rotate out of cucurbits.',
          sourceCitation: 'Dubón (2006)',
        ),
      ];
    }

    // 5. SANDÍA / WATERMELON
    if (lower.contains('sandía') || lower.contains('sandia') || lower.contains('watermelon')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Pulga Saltona, Gusano Cogollero y Trozador'
              : 'Flea Beetle, Fall Armyworm & Cutworm',
          scientificName: 'Epitrix spp. / Spodoptera frugiperda / Agrotis spp.',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Emergencia de plántulas y desarrollo de guías/frutos'
              : 'Seedling emergence and vine/fruit development',
          symptomsAndImpact: es
              ? 'La pulga saltona perfora agujeros redondos causando caída de hojas; el trozador corta los tallos a ras del suelo y el cogollero daña follaje y frutos.'
              : 'Flea beetles chew round holes causing leaf drop; cutworms sever stems at soil level, and armyworms damage foliage and fruit.',
          preventionAction: es
              ? 'Proteger plántulas en las primeras 3 semanas y limpiar rastrojos antes de la siembra.'
              : 'Protect seedlings during the first 3 weeks and clear crop residue prior to planting.',
          sourceCitation: 'Cañizo (s.f.); Investigación Biotecnológica Eva-Bits (2026)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Nematodos y Ninfas de Mosquita Blanca'
              : 'Root-Knot Nematodes & Whitefly Nymphs',
          scientificName: 'Meloidogyne spp. / Aleyrodidae',
          riskLevel: isSandy ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Suelos sueltos/arenosos y clima cálido'
              : 'Loose/sandy soils and warm weather',
          symptomsAndImpact: es
              ? 'Los nematodos provocan marchitez, clorosis y enanismo; las ninfas de mosquita blanca succionan nutrientes causando amarillamiento y encrespamiento foliar.'
              : 'Nematodes cause wilting, chlorosis, and stunting; whitefly nymphs suck nutrients causing leaf yellowing and curling.',
          preventionAction: es
              ? 'Rotar con Crotalaria (abono verde nematicida) e incorporar materia orgánica al suelo.'
              : 'Rotate with Crotalaria (nematicidal green manure) and incorporate organic matter into the soil.',
          sourceCitation: 'Investigación Biotecnológica Eva-Bits (2026)',
        ),
      ];
    }

    // 6. PIÑA / PINEAPPLE (Monge, 2018)
    if (lower.contains('piña') || lower.contains('pina') || lower.contains('pineapple')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Tecla de la Piña y Gusano Soldado'
              : 'Pineapple Fruit Borer (Tecla) & Armyworm',
          scientificName: 'Strymon megarus / Spodoptera spp.',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Floración y formación del fruto'
              : 'Flowering and fruit development',
          symptomsAndImpact: es
              ? 'La larva de tecla perfora el fruto creando galerías y exudado ámbar ("gomosis"), dejando orificios para hongos/bacterias que causan rechazo comercial; el gusano soldado raspa los "ojos" oxidando el tejido.'
              : 'The Tecla larva bores into the fruit creating galleries and amber exudate ("gummosis"), opening entry points for fungi/bacteria; armyworms scrape around the "eyes" causing tissue oxidation.',
          preventionAction: es
              ? 'Proteger la inflorescencia desde la floración y eliminar frutos con gomosis.'
              : 'Protect inflorescences from flowering onward and remove fruits showing gummosis.',
          sourceCitation: 'Monge (2018)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Picudo, Sinfílidos ("Escoba de Bruja") y Pudrición Acuosa'
              : 'Weevil, Root Symphylids ("Witch\'s Broom") & Watery Rot',
          scientificName: 'Metamasius dimidiatipennis / Scutigerella / Thielaviopsis',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Suelos húmedos y material de siembra expuesto'
              : 'Humid soils and exposed planting material',
          symptomsAndImpact: es
              ? 'El picudo anida dentro del tallo causando pudrición y muerte; pequeños insectos blancos radiculares frenan nutrientes provocando "escoba de bruja" en parches; el hongo de pudrición acuosa (conidioesporas y clamidosporas) pudre tallo y fruto.'
              : 'Weevils nest inside stems causing rot and death; small white root insects block nutrient uptake causing patchy "witch\'s broom"; watery rot fungus rots stems and fruit.',
          preventionAction: es
              ? 'Desinfectar hijos/coronas antes de sembrar y asegurar drenaje profundo en suelos arcillosos.'
              : 'Disinfect slips/crowns before planting and ensure deep drainage in clay soils.',
          sourceCitation: 'Monge (2018)',
        ),
      ];
    }

    // 7. MANZANA / APPLE (Murray y Aiston, 2012)
    if (lower.contains('manzana') || lower.contains('apple')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Hongo Oídio y Polilla de la Manzana'
              : 'Powdery Mildew (Oídio) & Codling Moth',
          scientificName: 'Podosphaera leucotricha / Cydia pomonella',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Finales de primavera y días cálidos con viento, rocío o riego'
              : 'Late spring and warm days with wind, dew, or irrigation',
          symptomsAndImpact: es
              ? 'El oídio inverna en ramas y ataca variedades Jonathan, Idared, Gala, Jonagold y Roma en tallos, flores y frutos; la polilla deposita larvas dentro del fruto causando pudrición y caída de frutos verdes.'
              : 'Powdery mildew overwinters on branches and attacks Jonathan, Idared, Gala, Jonagold, and Roma varieties; codling moth larvae bore into fruit causing rot and premature drop.',
          preventionAction: es
              ? 'Podar ramas afectadas en invierno y evitar riego por aspersión sobre el follaje en días cálidos.'
              : 'Prune affected branches in winter and avoid overhead sprinkler irrigation on warm days.',
          sourceCitation: 'Murray y Aiston (2012)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Piojo de San José, Ácaro Araña Roja y Áfidos'
              : 'San Jose Scale, Red Spider Mite & Aphids',
          scientificName: 'Quadraspidiotus perniciosus / Panonychus ulmi',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Climas cálidos y finales de verano'
              : 'Warm climates and late summer',
          symptomsAndImpact: es
              ? 'El piojo de San José crea halos rojos con centro blanco en corteza y fruta pudiendo matar al árbol; la araña roja deja punteado foliar y los áfidos debilitan el floema deformando frutos.'
              : 'San Jose scale creates red halos with white centers on bark and fruit and can kill the tree; red spider mites stipple leaves and aphids weaken phloem deforming fruit.',
          preventionAction: es
              ? 'Inspeccionar la base de los árboles y corteza, y controlar malezas huéspedes en verano.'
              : 'Inspect tree bases and bark, and manage alternate weed hosts during summer.',
          sourceCitation: 'Murray y Aiston (2012)',
        ),
      ];
    }

    // 8. NARANJA / CÍTRICOS / ORANGE (Delgado, 2024)
    if (lower.contains('naranja') || lower.contains('cítric') || lower.contains('orange')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Piojo Rojo de California (Escama Roja)'
              : 'California Red Scale (Escama Roja)',
          scientificName: 'Aonidiella aurantii',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Temperaturas cálidas y baja humedad relativa'
              : 'Warm temperatures and low relative humidity',
          symptomsAndImpact: es
              ? 'Hemíptero altamente peligroso y destructivo para los naranjos que se alimenta de la savia de ramas, hojas y frutos.'
              : 'Highly dangerous and destructive hemipteran pest in orange groves that feeds on tree sap.',
          preventionAction: es
              ? 'Realizar podas de aireación y liberar controladores biológicos o aceites minerales selectivos.'
              : 'Perform aeration pruning and release biological control agents or selective mineral oils.',
          sourceCitation: 'Delgado (2024)',
        ),
        CropPestWarning(
          pestName: es ? 'Mosca de la Fruta' : 'Fruit Fly',
          scientificName: 'Ceratitis capitata / Anastrepha spp.',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Maduración de frutos cítricos'
              : 'Citrus fruit ripening period',
          symptomsAndImpact: es
              ? 'Infesta directamente los frutos perforando la cáscara y provocando pudrición interna y caída.'
              : 'Directly infests fruits by puncturing the rind, causing internal decay and fruit drop.',
          preventionAction: es
              ? 'Colocar trampas McPhail con proteína hidrolizada y recolectar frutos caídos.'
              : 'Deploy McPhail traps with hydrolyzed protein and collect fallen fruit.',
          sourceCitation: 'Delgado (2024)',
        ),
      ];
    }

    // 9. CAÑA DE AZÚCAR / SUGARCANE (Campos Hernández & Lugo Alonso, 2012)
    if (lower.contains('caña') || lower.contains('cana') || lower.contains('sugar')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Pokka Boeng (Cogollo Retorcido)'
              : 'Pokka Boeng (Twisted Top Disease)',
          scientificName: 'Fusarium spp. (Complejo fúngico)',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Humedad elevada tras periodos secos'
              : 'High moisture following dry periods',
          symptomsAndImpact: es
              ? 'Hongo que causa pudrición de raíces, menor absorción de agua y nutrientes, y marchitamientos de hasta el 50% del cultivo.'
              : 'Fungus causing root rot, reduced water and nutrient uptake, and wilting in up to 50% of the crop.',
          preventionAction: es
              ? 'Mejorar el drenaje parcelario y utilizar semilla sana libre de infección.'
              : 'Improve parcel drainage and use certified disease-free seed cane.',
          sourceCitation: 'Campos Hernández & Lugo Alonso (2012)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Picudo del Tronco y Pulgón Amarillo'
              : 'Sugarcane Stem Weevil & Yellow Sugarcane Aphid',
          scientificName: 'Metamasius / Sipha flava',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Brotación de retoños y estrés hídrico'
              : 'Ratoon sprouting and water stress',
          symptomsAndImpact: es
              ? 'El picudo causa hasta 10% de pérdida del cultivo, 40% de daño en retoños y pudrimiento del cogollo hasta la muerte de la planta; el pulgón amarillo drena la savia secando las hojas.'
              : 'The stem weevil causes up to 10% crop loss, 40% ratoon damage, and whorl rot leading to plant death; yellow aphids drain sap drying out leaves.',
          preventionAction: es
              ? 'Tratar los cortes de cosecha y eliminar residuos infestados en la cepa.'
              : 'Treat harvest cuts and remove infested residue around ratoons.',
          sourceCitation: 'Campos Hernández & Lugo Alonso (2012)',
        ),
      ];
    }

    // 10. TRIGO / WHEAT
    if (lower.contains('trigo') || lower.contains('wheat')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Pulgones del Trigo y Chinches del Trigo'
              : 'Wheat Aphids & Wheat Stink Bugs',
          scientificName: 'Schizaphis graminum / Hemiptera',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Etapa de espigado y llenado de granos'
              : 'Heading and grain-filling stage',
          symptomsAndImpact: es
              ? 'Los pulgones reducen el peso del grano y su rendimiento; los chinches succionan el tejido vegetal y espigas provocando vaciamiento celular (partes blancas).'
              : 'Aphids reduce grain weight and yield; stink bugs suck plant tissue and spikes causing cellular emptying (bleached white tissue).',
          preventionAction: es
              ? 'Monitorear espigas durante el llenado de grano y rotar con leguminosas.'
              : 'Monitor spikes during grain filling and rotate with legumes.',
          sourceCitation: 'Investigación Biotecnológica Eva-Bits (2026)',
        ),
        CropPestWarning(
          pestName: es ? 'Coro de las Pasturas' : 'Pasture White Grub (Coro)',
          scientificName: 'Diloboderus abderus',
          riskLevel: 'moderate',
          climateTrigger: es
              ? 'Presencia de rastrojos en superficie'
              : 'Surface crop residue where females nest',
          symptomsAndImpact: es
              ? 'Se alimenta de raíces y tallos del trigo; la hembra construye el nido llevando rastrojos para colocar sus huevos por encima.'
              : 'Feeds on wheat roots and stems; females build nests using surface crop residue to lay eggs.',
          preventionAction: es
              ? 'Inspeccionar el suelo bajo rastrojos antes de la siembra.'
              : 'Inspect soil beneath crop residues prior to planting.',
          sourceCitation: 'Investigación Biotecnológica Eva-Bits (2026)',
        ),
      ];
    }

    // 11. ARROZ / RICE (JICA, s.f.)
    if (lower.contains('arroz') || lower.contains('rice')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Tizón de la Hoja y Mancha Circular'
              : 'Rice Leaf Blight & Circular Brown Spot',
          scientificName: 'Pyricularia / Helminthosporium',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Condiciones cálidas, alta humedad y radiación solar'
              : 'Warm conditions, high humidity, and solar radiation',
          symptomsAndImpact: es
              ? 'El tizón afecta hoja, tallo y espiga en climas cálidos y húmedos; la mancha circular produce lesiones color chocolate en hoja, tallo y cascabillo.'
              : 'Leaf blight affects leaves, stems, and panicles in warm humid climates; circular spot causes chocolate-colored lesions on leaves, stems, and hulls.',
          preventionAction: es
              ? 'Evitar excesos de nitrógeno mineral y manejar láminas de agua intermitentes.'
              : 'Avoid excessive mineral nitrogen and manage intermittent water depths.',
          sourceCitation: 'Agencia de Cooperación Internacional del Japón (JICA, s.f.)',
        ),
      ];
    }

    // 12. BANANO Y PLÁTANO / BANANA & PLANTAIN (Deiss, 2025)
    if (lower.contains('banan') || lower.contains('plátan') || lower.contains('platan') || lower.contains('plantain')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Sigatoka Negra'
              : 'Black Sigatoka',
          scientificName: 'Mycosphaerella fijiensis',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Climas húmedos y cálidos con dispersión por agua y viento'
              : 'Warm, humid climates with spore dispersal by water and wind',
          symptomsAndImpact: es
              ? 'Enfermedad fúngica cuyas esporas se propagan por las hojas antes de penetrar el tejido, destruyendo el área foliar fotosintética.'
              : 'Fungal disease whose spores spread across leaves by rain and wind before penetrating tissue, destroying photosynthetic leaf area.',
          preventionAction: es
              ? 'Deshoje sanitario periódico y drenaje eficiente para reducir la humedad relativa dentro de la plantación.'
              : 'Perform regular sanitary deleafing and maintain efficient drainage to reduce canopy humidity.',
          sourceCitation: 'Deiss (2025)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Pulgón del Banano y Gorgojo del Plátano'
              : 'Banana Aphid & Corm Weevil',
          scientificName: 'Pentalonia nigronervosa / Cosmopolites sordidus',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Brotación de hijos y cormos húmedos'
              : 'Sucker sprouting and moist corms',
          symptomsAndImpact: es
              ? 'El pulgón perfora el tejido y transmite el virus del racimo del banano (enfermedad de la copa abultada); el gorgojo perfora tallos, hojas, brotes y raíces.'
              : 'The banana aphid transmits Banana Bunchy Top Virus; the weevil tunnels into stems, shoots, and roots.',
          preventionAction: es
              ? 'Usar trampas de pseudotallo para el gorgojo y eliminar plantas con síntoma de copa abultada.'
              : 'Use pseudostem traps for weevils and rogue plants showing bunchy top symptoms.',
          sourceCitation: 'Deiss (2025)',
        ),
      ];
    }

    // 13. MANGO (Sihdu, 2022)
    if (lower.contains('mango')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Barrenadores del Mango, Gorgojo de la Semilla y Chicharrita'
              : 'Mango Stem Borers, Seed Weevil & Leafhopper',
          scientificName: 'Cerambycidae / Sternochetus mangiferae / Cicadellidae',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Ramas leñosas y etapa de floración/fructificación'
              : 'Woody branches and flowering/fruiting stage',
          symptomsAndImpact: es
              ? 'Los machos barrenadores roen la corteza para que las larvas creen cavidades en los tallos principales pudiendo matar al árbol; el gorgojo destruye el fruto desde la semilla y la chicharrita drena la savia secando brotes.'
              : 'Male borers girdle bark so larvae tunnel cavities in main stems that can kill the tree; seed weevils destroy fruit from within and leafhoppers drain sap.',
          preventionAction: es
              ? 'Podar ramas con desprendimiento de corteza y recolectar frutos caídos prematuramente.'
              : 'Prune branches showing bark detachment and collect prematurely fallen fruit.',
          sourceCitation: 'Sihdu (2022)',
        ),
      ];
    }

    // 14. SOYA / SOJA / SOYBEAN (Agrotec, 2025)
    if (lower.contains('soya') || lower.contains('soja') || lower.contains('soy')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Chinche Marrón y Orugas Defoliadoras'
              : 'Brown Stink Bug & Defoliating Caterpillars',
          scientificName: 'Euschistus heros / Anticarsia gemmatalis',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Formación de vainas y llenado de grano'
              : 'Pod formation and grain filling',
          symptomsAndImpact: es
              ? 'El chinche marrón succiona savia de vainas y granos provocando caída de granos, retención foliar y arrugamiento; las orugas pueden dañar completamente la planta.'
              : 'Brown stink bugs suck sap from pods and seeds causing pod drop, foliar retention, and shriveling; caterpillars can completely defoliate plants.',
          preventionAction: es
              ? 'Monitoreo con paño vertical en bordes del lote y rotación con gramíneas.'
              : 'Monitor with beat cloths along parcel borders and rotate with grasses.',
          sourceCitation: 'Agrotec (2025)',
        ),
        CropPestWarning(
          pestName: es
              ? 'Termitas Subterráneas en Suelo Arenoso/Seco'
              : 'Subterranean Termites in Dry/Sandy Soil',
          scientificName: 'Isoptera',
          riskLevel: (isSandy || isDryWarm) ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Suelos arenosos y secos (Suelo actual: $soilType)'
              : 'Sandy and dry soils (Current soil: $soilType)',
          symptomsAndImpact: es
              ? 'Aprovechan suelos arenosos y secos para atacar raíces de plántulas, causando fallas y marchitez en manchones que suele confundirse con deficiencia de nutrientes.'
              : 'Exploit dry sandy soils to attack seedling roots, causing patchy wilting often misdiagnosed as nutrient deficiency.',
          preventionAction: es
              ? 'Inspeccionar raíces en manchones amarillos y mantener humedad radicular uniforme.'
              : 'Inspect roots in yellow patches and maintain uniform root-zone moisture.',
          sourceCitation: 'Agrotec (2025)',
        ),
      ];
    }

    // Default multi-crop fallback (Maíz + Frijol)
    return [
      CropPestWarning(
        pestName: es
            ? 'Gusano Cogollero y Mosca Blanca'
            : 'Fall Armyworm & Whitefly Complex',
        scientificName: 'Spodoptera frugiperda / Bemisia',
        riskLevel: 'high',
        climateTrigger: es
            ? 'Variabilidad térmica y colindancia entre parcelas'
            : 'Thermal variability and parcel adjacency',
        symptomsAndImpact: es
            ? 'Riesgo de rápida colonización foliar y transmisión viral entre sublotes colindantes.'
            : 'Risk of rapid foliar colonization and viral transmission across adjacent subplots.',
        preventionAction: es
            ? 'Alternar familias botánicas (Gramíneas -> Leguminosas) y vigilar bordes del lote.'
            : 'Alternate botanical families (Grasses -> Legumes) and scout parcel borders.',
        sourceCitation: 'Vilela (2026); Dubón (2006)',
      ),
    ];
  }

  /// Returns the Precision Irrigation Systems Catalog tailored to the soil type
  /// Grounded in (Alianza Bioversity and CIAT, 2026) and (Misión NASA-ISRO NISAR - NASA Ciencia, s.f.)
  static List<IrrigationSystemOption> getIrrigationSystemsForSoil({
    required String soilType,
    required double recommendedWaterMm,
    bool? isSpanish,
  }) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    final lower = soilType.toLowerCase();
    final isSandy = lower.contains('aren') || lower.contains('sand');
    final isClay = lower.contains('arcill') || lower.contains('clay');
    final isSilt = lower.contains('lim') || lower.contains('silt');
    final isLoam = !isSandy && !isClay && !isSilt;

    return [
      IrrigationSystemOption(
        systemName: es
            ? 'Riego por Goteo de Alta Frecuencia (Por Pulsos)'
            : 'High-Frequency Pulse Drip Irrigation',
        efficiencyPct: '92% - 95%',
        bestForSoil: es ? 'Suelo Arenoso y Franco' : 'Sandy & Loam Soils',
        description: es
            ? 'Suministra la lámina requerida (${recommendedWaterMm.toStringAsFixed(0)} mm) en fracciones cortas y frecuentes directo a la raíz. En suelos arenosos evita que el agua y los nutrientes se pierdan por filtración profunda.'
            : 'Delivers the required depth (${recommendedWaterMm.toStringAsFixed(0)} mm) in short, frequent pulses directly to the root zone. In sandy soils, it prevents water and nutrient loss.',
        nasaIntegrationNote: es
            ? 'Ideal para reponer únicamente el agua evaporada durante el día.'
            : 'Ideal for replacing only the water evaporated during the day.',
        isRecommendedForCurrentSoil: isSandy || isLoam,
      ),
      IrrigationSystemOption(
        systemName: es
            ? 'Microaspersión de Baja Presión con Cobertura (Mulch)'
            : 'Low-Pressure Micro-Sprinkler with Organic Mulch',
        efficiencyPct: '85% - 88%',
        bestForSoil: es ? 'Suelo Limoso y Laderas' : 'Silt Soils & Sloped Terrain',
        description: es
            ? 'Distribuye gotas finas sin golpear el suelo. Como el suelo limoso tiende a compactarse cuando está descubierto en terrenos inclinados, combinar microaspersión con cobertura vegetal preserva su textura suave y alta fertilidad.'
            : 'Distributes fine droplets gently. Since silty soil compacts easily when bare on sloped terrain, pairing micro-sprinklers with mulch preserves its smooth texture and fertility.',
        nasaIntegrationNote: es
            ? 'Se recomienda suspender el riego antes de lluvias pronosticadas.'
            : 'Suspend irrigation prior to forecasted rainfall.',
        isRecommendedForCurrentSoil: isSilt,
      ),
      IrrigationSystemOption(
        systemName: es
            ? 'Goteo de Bajo Caudal Intermitente con Zanjas de Drenaje'
            : 'Low-Flow Intermittent Drip with Drainage Channels',
        efficiencyPct: '90%',
        bestForSoil: es ? 'Suelo Arcilloso' : 'Clay Soils',
        description: es
            ? 'El suelo arcilloso retiene el agua con facilidad pero drena lento, volviéndose pesado y pegajoso. El caudal bajo evita el encharcamiento superficial y permite que el oxígeno llegue a las raíces.'
            : 'Clay soil retains water easily but drains slowly, becoming heavy and sticky. Low-flow emitters prevent surface ponding and root asphyxia.',
        nasaIntegrationNote: es
            ? 'Evita superar el 75% de saturación de humedad en la raíz.'
            : 'Avoids exceeding 75% root-zone moisture saturation.',
        isRecommendedForCurrentSoil: isClay,
      ),
      IrrigationSystemOption(
        systemName: es
            ? 'Riego por Surcos Alternos'
            : 'Alternate Furrow Irrigation',
        efficiencyPct: '75% - 80%',
        bestForSoil: es ? 'Suelo Franco (Bajo Costo)' : 'Loam Soil (Low Cost)',
        description: es
            ? 'Alternativa económica para pequeños productores que riega un surco sí y otro no, reduciendo el consumo de agua en 35% mientras aprovecha la retención balanceada del suelo franco.'
            : 'Cost-effective option for smallholders that waters every other furrow, cutting water use by 35% while leveraging the balanced retention of loam soil.',
        nasaIntegrationNote: es
            ? 'Ajusta los turnos según la humedad real de tu parcela.'
            : 'Adjust watering intervals based on your parcel\'s actual moisture.',
        isRecommendedForCurrentSoil: isLoam,
      ),
    ];
  }

  /// Generates the 3-Week Rolling Projection (Day 1 to Day 21) and 7-Day Checkpoint Delta
  static ThreeWeekProjection generateThreeWeekProjection({
    required String crop,
    required String soilType,
    required double tempC,
    required double rain7dMm,
    required double soilMoisturePct,
    required double weeklyDeficitMm,
    required double accumulatedGdd7d,
    required String suggestedRotationCrop,
    DateTime? referenceDate,
    bool? isSpanish,
  }) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    final now = referenceDate ?? DateTime.now();

    final w1Start = now;
    final w1End = now.add(const Duration(days: 7));
    final w2Start = now.add(const Duration(days: 8));
    final w2End = now.add(const Duration(days: 14));
    final w3Start = now.add(const Duration(days: 15));
    final w3End = now.add(const Duration(days: 21));

    final prevWeekStart = now.subtract(const Duration(days: 7));

    final fullRange = '${_formatShortDate(w1Start)} - ${_formatShortDate(w3End)}';
    final checkpointPeriod =
        '${_formatShortDate(prevWeekStart)} -> ${_formatShortDate(now)}';

    final gdd14d = (accumulatedGdd7d * 2).toStringAsFixed(0);
    final gdd21d = (accumulatedGdd7d * 3).toStringAsFixed(0);
    final projectedMoistureW2 =
        (soilMoisturePct - (weeklyDeficitMm * 0.35)).clamp(24.0, 88.0).toStringAsFixed(0);
    final projectedMoistureW3 =
        (soilMoisturePct - (weeklyDeficitMm * 0.60)).clamp(20.0, 85.0).toStringAsFixed(0);

    final phases = [
      WeeklyProjectionPhase(
        weekNumber: 1,
        dateRangeLabel: '${_formatShortDate(w1Start)} - ${_formatShortDate(w1End)}',
        title: es
            ? 'Semana 1: Ajuste de Riego y Revisión de Plagas'
            : 'Week 1: Irrigation Adjustment & Pest Check',
        expectedMetrics: es
            ? 'Humedad: ${soilMoisturePct.toStringAsFixed(0)}% • Déficit: ${weeklyDeficitMm.toStringAsFixed(1)} mm • +${accumulatedGdd7d.toStringAsFixed(0)} GDD'
            : 'Moisture: ${soilMoisturePct.toStringAsFixed(0)}% • Deficit: ${weeklyDeficitMm.toStringAsFixed(1)} mm • +${accumulatedGdd7d.toStringAsFixed(0)} GDD',
        recommendedAction: es
            ? 'Aplicar riego según tu suelo ($soilType) e inspeccionar posibles focos iniciales de plagas en $crop.'
            : 'Apply irrigation tailored to $soilType soil and scout for initial pest hotspots in $crop.',
      ),
      WeeklyProjectionPhase(
        weekNumber: 2,
        dateRangeLabel: '${_formatShortDate(w2Start)} - ${_formatShortDate(w2End)}',
        title: es
            ? 'Semana 2: Crecimiento del Cultivo y Vigilancia de Lluvias'
            : 'Week 2: Crop Growth & Rainfall Watch',
        expectedMetrics: es
            ? 'Humedad proyectada sin riego: ~$projectedMoistureW2% • Calor acumulado: ~$gdd14d GDD'
            : 'Projected unwatered moisture: ~$projectedMoistureW2% • Cumulative heat: ~$gdd14d GDD',
        recommendedAction: es
            ? 'Si la humedad baja del 45%, activar pulsos de riego y reforzar medidas preventivas en el cultivo.'
            : 'If moisture drops below 45%, trigger pulse irrigation and reinforce preventive crop care.',
      ),
      WeeklyProjectionPhase(
        weekNumber: 3,
        dateRangeLabel: '${_formatShortDate(w3Start)} - ${_formatShortDate(w3End)}',
        title: es
            ? 'Semana 3: Nutrición del Suelo y Plan de Rotación'
            : 'Week 3: Soil Nutrition & Rotation Plan',
        expectedMetrics: es
            ? 'Humedad proyectada: ~$projectedMoistureW3% • Suma térmica 21 días: ~$gdd21d GDD'
            : 'Projected moisture: ~$projectedMoistureW3% • 21-day thermal sum: ~$gdd21d GDD',
        recommendedAction: es
            ? 'Preparar incorporación de abono verde o transición hacia $suggestedRotationCrop para aportar nitrógeno y cortar ciclos de plagas.'
            : 'Prepare green manure incorporation or transition toward $suggestedRotationCrop to add nitrogen and break pest cycles.',
      ),
    ];

    final changes = es
        ? [
            'La humedad en la raíz pasó de ${(soilMoisturePct + 4.5).clamp(20, 95).toStringAsFixed(0)}% a ${soilMoisturePct.toStringAsFixed(0)}% en los últimos 7 días (${weeklyDeficitMm > 15 ? 'descenso por evaporación' : 'reserva estable'}).',
            'Se acumularon +${accumulatedGdd7d.toStringAsFixed(1)} GDD de calor, acelerando el crecimiento de $crop y la posible actividad de insectos.',
            'Alertas de plagas actualizadas para $crop en suelo $soilType.',
          ]
        : [
            'Root-zone moisture shifted from ${(soilMoisturePct + 4.5).clamp(20, 95).toStringAsFixed(0)}% to ${soilMoisturePct.toStringAsFixed(0)}% over the past 7 days (${weeklyDeficitMm > 15 ? 'evaporation drawdown' : 'stable reserve'}).',
            'Accumulated +${accumulatedGdd7d.toStringAsFixed(1)} GDD of heat, advancing $crop growth and potential insect activity.',
            'Updated pest alerts for $crop in $soilType soil.',
          ];

    return ThreeWeekProjection(
      fullDateRange: fullRange,
      phases: phases,
      longTermClimateNote: es
          ? 'Planificar por bloques de 3 semanas te permite anticipar sequías y olas de calor a tiempo.'
          : 'Planning in 3-week blocks helps you anticipate droughts and heatwaves ahead of time.',
      weeklyCheckpointTitle: es
          ? 'Cambios de la Última Semana (Últimos 7 Días)'
          : 'Past Week Changes (Last 7 Days)',
      weeklyCheckpointPeriod: checkpointPeriod,
      weeklyCheckpointSummary: es
          ? 'Comparación de hace 1 semana con el estado actual de tu parcela:'
          : 'Comparison from 1 week ago with your parcel\'s current state:',
      weeklyChangesDetected: changes,
    );
  }
}
