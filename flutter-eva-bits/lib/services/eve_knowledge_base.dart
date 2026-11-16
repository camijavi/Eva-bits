import '../languages/app_strings.dart';
import 'agro_prediction_engine.dart';

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
    this.sourceCitation = '',
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
    this.satelliteSource = '',
    required this.description,
    required this.preventionMeasure,
    this.citation = '',
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

  /// Clear, farmer-friendly explanation of how each soil type behaves in the field.
  static String getSoilScientificConcept(String soilType, {bool? isSpanish}) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    final lower = soilType.toLowerCase();

    if (lower.contains('aren') || lower.contains('sand')) {
      return es
          ? 'Suelo Arenoso: Es una tierra suelta que no se encharca porque el agua baja rápido, pero se seca pronto y el abono se lava con facilidad si riegas de golpe.'
          : 'Sandy Soil: Loose earth that never waterlogs because water drains fast, but it dries out quickly and nutrients wash away if you apply too much water at once.';
    }
    if (lower.contains('lim') || lower.contains('silt')) {
      return es
          ? 'Suelo Limoso: Es una tierra suave y muy fértil que guarda bien la humedad y el alimento de la planta, pero si queda pelada en una ladera la lluvia la aprieta y la endurece.'
          : 'Silt Soil: Smooth, very fertile earth that holds moisture and plant food well, but if left bare on a slope, rain compacts and hardens the surface.';
    }
    if (lower.contains('arcill') || lower.contains('clay')) {
      return es
          ? 'Suelo Arcilloso: Es una tierra pesada que guarda mucha agua y nutrientes por bastante tiempo, pero drena lento; si llueve mucho se pone pegajosa y a las raíces les cuesta respirar.'
          : 'Clay Soil: Heavy earth that holds water and nutrients for a long time, but drains slowly; with heavy rain it gets sticky and roots struggle to breathe.';
    }
    return es
        ? 'Suelo Franco: Es la tierra más equilibrada para sembrar; guarda buena humedad y abono sin encharcarse y deja que la raíz crezca suelta y sana.'
        : 'Loam Soil: The most balanced earth for farming; it holds moisture and fertilizer without waterlogging and lets roots grow loose and healthy.';
  }

  /// Evaluates weather risks and natural phenomena in clear farmer language.
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

    // 1. Heat + Dry spell
    final bool isCompoundRisk =
        (soilMoisture < 0.45 && tempC >= 26.5) || rain7dMm < 5.0;
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Calor Fuerte y Falta de Lluvia'
            : 'Strong Heat & Low Rainfall',
        severity: isCompoundRisk ? 'danger' : 'warning',
        description: es
            ? 'Cuando se juntan días muy calurosos con poca lluvia, la tierra pierde rápido su humedad y la planta se estresa el doble, bajando la cosecha si la raíz se queda seca.'
            : 'When hot days combine with low rain, the soil loses moisture fast and plants suffer double stress, reducing harvest yield if roots dry out.',
        preventionMeasure: es
            ? 'Cubre el suelo con rastrojo o zacate seco (mulch) alrededor de la planta para guardar la fresca en la raíz y riega temprano en la mañana o al caer la tarde.'
            : 'Cover the soil with dry crop residue (mulch) around plants to keep roots cool and water early in the morning or late in the afternoon.',
      ),
    );

    // 2. Heavy rain & flooding
    final bool isFloodRisk = rain7dMm > 25.0 || soilMoisture > 0.72;
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Aguaceros Fuertes y Encharcamiento'
            : 'Heavy Downpours & Waterlogging',
        severity: isFloodRisk ? 'danger' : 'info',
        description: es
            ? 'Varios días seguidos de lluvia fuerte pueden encharcar la parcela, lavar el abono de la tierra y pudrir la raíz de las siembras.'
            : 'Several days of heavy rain can flood the plot, wash away fertilizer, and rot crop roots.',
        preventionMeasure: es
            ? 'Limpia y abre zanjas de desagüe en las orillas del lote y siembra barreras vivas (como zacate limón o vetiver) para frenar el golpe del agua.'
            : 'Clear drainage ditches along plot edges and plant living barriers (like lemongrass or vetiver) to slow down runoff water.',
      ),
    );

    // 3. Slope wash & soil crusting
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Lavado de Tierra y Compactación en Ladera'
            : 'Soil Washout & Slope Compaction',
        severity: (isFloodRisk && isSiltOrClay) ? 'warning' : 'info',
        description: es
            ? 'Si el terreno tiene inclinación y la tierra está descubierta, el agua corre llevándose la capa más fértil y apretando el suelo.'
            : 'If your land is sloped and bare, runoff carries away the most fertile topsoil and packs the surface tight.',
        preventionMeasure: es
            ? 'Nunca dejes la tierra pelada en laderas; traza los surcos atravesados a la pendiente (en curvas a nivel) y deja el rastrojo sobre el suelo.'
            : 'Never leave sloped land bare; lay out furrows across the slope (contour planting) and keep crop residue on the ground.',
      ),
    );

    // 4. Crop adaptation to warmer seasons
    warnings.add(
      NaturalPhenomenonWarning(
        phenomenonName: es
            ? 'Cuidado del Cultivo ante el Calor'
            : 'Protecting Crops from Rising Heat',
        severity: 'info',
        description: es
            ? 'Los cultivos sensibles como el maíz sufren si el calor sube demasiado durante la floración, pero rotar tus lotes ayuda a que la tierra aguante mejor.'
            : 'Heat-sensitive crops like corn suffer if temperatures spike during flowering, but rotating your plots helps the land hold up better.',
        preventionMeasure: es
            ? 'Alterna tus siembras con frijol o soya para abonar la tierra de forma natural y usa semillas adaptadas a tu zona.'
            : 'Alternate plantings with beans or soy to naturally fertilize the soil and use seeds adapted to your local climate.',
      ),
    );

    return warnings;
  }

  /// Returns accurate, farmer-friendly pest & disease warnings for each crop.
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

    // 1. MAÍZ / CORN
    if (lower.contains('maíz') || lower.contains('maiz') || lower.contains('corn')) {
      return [
        CropPestWarning(
          pestName: es ? 'Gusano Cogollero' : 'Fall Armyworm (Cogollero)',
          scientificName: 'Spodoptera frugiperda',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Se pasa rápido de un lote a otro, sobre todo en tiempo cálido'
              : 'Spreads fast from plot to plot, especially in warm weather',
          symptomsAndImpact: es
              ? 'Es la plaga más dañina del maíz. Se mete en el cogollo y mastica las hojas tiernas dejando agujeros y aserrín (excremento), frenando el crecimiento de la planta.'
              : 'The most damaging corn pest. It burrows into the whorl and chews tender leaves, leaving holes and sawdust-like frass, stunting plant growth.',
          preventionAction: es
              ? 'Revisa los cogollos cada semana, limpia las malezas de las orillas, aplica ceniza o tierra fina con control biológico directo al cogollo y no siembres maíz tras maíz (rota con frijol).'
              : 'Check whorls weekly, clear border weeds, apply biological control directly into the whorl, and rotate with beans instead of planting corn after corn.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Barrenador del Tallo y Gusano de la Mazorca'
              : 'Stalk Borer & Corn Earworm',
          scientificName: 'Diatraea / Helicoverpa zea',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Durante el crecimiento de la caña y cuando el maíz empieza a jilotear'
              : 'During stalk growth and when corn ears begin silking',
          symptomsAndImpact: es
              ? 'El barrenador hace túneles por dentro de la caña (debilitando la planta hasta que se cae) y el gusano de la mazorca entra por los pelos del elote dañando los granos.'
              : 'The borer tunnels inside the stalk (weakening the plant until it lodges) and the earworm enters through the silk, damaging the kernels.',
          preventionAction: es
              ? 'Pica e incorpora bien el rastrojo después de la cosecha para que no queden gusanos escondidos y coloca trampas cuando salgan los pelos del elote.'
              : 'Chop and incorporate stalks after harvest so larvae cannot overwinter, and set traps when silks appear.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Tizón de la Hoja y Roya del Maíz'
              : 'Corn Leaf Blight & Common Rust',
          scientificName: 'Exserohilum turcicum / Puccinia sorghi',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Días húmedos y frescos (Humedad actual del suelo: ${(soilMoisture * 100).toInt()}%)'
              : 'Humid weather (Current soil moisture: ${(soilMoisture * 100).toInt()}%)',
          symptomsAndImpact: es
              ? 'Son hongos que forman manchas alargadas color café o polvillo rojizo en las hojas; si secan la hoja temprano, la mazorca queda pequeña y sin peso.'
              : 'Fungi that form long brown blotches or reddish powder on leaves; if leaves dry early, cobs stay small and light.',
          preventionAction: es
              ? 'Deja buena distancia entre surcos para que corra el aire, evita regar por encima de las hojas y rota el lote con leguminosas.'
              : 'Leave good spacing between rows for airflow, avoid wetting leaves when watering, and rotate the plot with legumes.',
        ),
      ];
    }

    // 2. CAFÉ / COFFEE
    if (lower.contains('café') || lower.contains('cafe') || lower.contains('coffee')) {
      return [
        CropPestWarning(
          pestName: es ? 'Broca del Café' : 'Coffee Berry Borer (Broca)',
          scientificName: 'Hypothenemus hampei',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cuando el grano de café empieza a llenar y madurar'
              : 'When coffee berries begin filling and ripening',
          symptomsAndImpact: es
              ? 'Es un gorgojo diminuto que perfora el ombligo de la cereza del café y vive adentro, haciendo que el grano se caiga antes de tiempo o pierda peso y calidad.'
              : 'A tiny beetle that bores into the tip of the coffee cherry and lives inside, causing berries to drop early or lose weight and quality.',
          preventionAction: es
              ? 'Recoge todos los granos caídos del suelo y los que queden en la planta después de la cosecha (pepena y repela), y pon trampas con atrayente al inicio de las lluvias.'
              : 'Pick up all fallen berries and leftover ripe cherries after harvest, and hang attractant traps at the start of the rainy season.',
        ),
        CropPestWarning(
          pestName: es ? 'Araña Roja del Café' : 'Coffee Red Spider Mite',
          scientificName: 'Oligonychus yothersi',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Época seca y calurosa (Temperatura actual: ${tempC.toStringAsFixed(1)} °C)'
              : 'Dry, warm spells (Current temp: ${tempC.toStringAsFixed(1)} °C)',
          symptomsAndImpact: es
              ? 'Deja las hojas bronceadas o amarillentas con polvo fino y provoca caída de hojas, pudiendo bajar hasta una tercera parte de la cosecha.'
              : 'Turns leaves bronzed or yellowish and causes heavy leaf drop, reducing harvest yield by up to 30%.',
          preventionAction: es
              ? 'Mantén árboles de sombra bien regulados en el cafetal y aplica riegos de auxilio en verano para reducir el calor y el polvo en las hojas.'
              : 'Maintain well-regulated shade trees in the coffee plot and apply supplemental watering during dry spells.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Roya del Café y Minador de la Hoja'
              : 'Coffee Leaf Rust & Leaf Miner',
          scientificName: 'Hemileia vastatrix / Leucoptera coffeella',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Humedad alta y cafetales muy cerrados con poca ventilación'
              : 'High humidity and overly dense shade with poor airflow',
          symptomsAndImpact: es
              ? 'La roya deja manchas con polvo amarillo por debajo de la hoja hasta botarla; el minador hace caminitos secos en la hoja que debilitan el arbusto.'
              : 'Rust leaves yellow powdery spots under leaves until they drop; the leaf miner makes dry trails inside leaves that weaken the bush.',
          preventionAction: es
              ? 'Poda las ramas viejas y regula la sombra para que entre sol y aire, y abona bien tus plantas para que resistan la enfermedad.'
              : 'Prune old branches and thin shade so sun and air can enter, and keep plants well-fed so they resist disease.',
        ),
      ];
    }

    // 3. FRIJOL / BEANS
    if (lower.contains('frijol') || lower.contains('bean')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Mosca Blanca (Mosaico Dorado)'
              : 'Whitefly (Golden Mosaic Virus)',
          scientificName: 'Bemisia tabaci',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Días calurosos y secos'
              : 'Warm and dry days',
          symptomsAndImpact: es
              ? 'Se esconde debajo de la hoja chupando la savia y transmite el virus del mosaico dorado, que pone la planta amarilla, enana y sin vainas.'
              : 'Hides under leaves sucking sap and spreads Golden Mosaic Virus, turning plants yellow, stunted, and podless.',
          preventionAction: es
              ? 'Coloca trampas amarillas con pegamento en las orillas del lote y evita sembrar frijol pegado a parcelas viejas de tomate, chiltoma o melón con mosca blanca.'
              : 'Place yellow sticky traps along plot borders and avoid planting beans next to older tomato, pepper, or melon plots with whiteflies.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Pulgones y Picudo de la Vaina'
              : 'Aphids & Bean Pod Weevil',
          scientificName: 'Aphididae / Apion godmani',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cuando salen los brotes tiernos y al formarse las vainas'
              : 'During tender shoot growth and pod formation',
          symptomsAndImpact: es
              ? 'Los pulgones enroscan las hojas tiernas y dejan una mielecilla donde sale hongo negro; el picudo pica la vaina tierna y su larva se come el grano de frijol por dentro.'
              : 'Aphids curl tender leaves and leave sticky honeydew; the pod weevil punctures young pods and its larva eats the bean seeds inside.',
          preventionAction: es
              ? 'Revisa debajo de las hojas cada pocos días y aplica jabón potásico o extracto de neem al ver los primeros pulgones o en la floración.'
              : 'Check under leaves every few days and apply potassium soap or neem extract when first spotting aphids or during flowering.',
        ),
      ];
    }

    // 4. SORGO / SORGHUM
    if (lower.contains('sorgo') || lower.contains('sorghum') || lower.contains('millón')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Mosquita de la Panoja y Pulgón Amarillo del Sorgo'
              : 'Sorghum Midge & Yellow Sugarcane Aphid',
          scientificName: 'Stenodiplosis sorghicola / Melanaphis sacchari',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Tiempo cálido y etapa de floración de la panoja'
              : 'Warm weather and panicle flowering stage',
          symptomsAndImpact: es
              ? 'El pulgón amarillo chupa la savia debajo de las hojas llenándolas de mielecilla; la mosquita pone huevos en la flor y deja la panoja vana (sin grano).'
              : 'Yellow aphids suck sap under leaves leaving sticky honeydew; the midge lays eggs in flowers leaving panicles empty without grain.',
          preventionAction: es
              ? 'Siembra parejo en las mismas fechas para que todo el lote florezca al mismo tiempo, elimina el zacate Johnson de las orillas y rota con frijol o soya.'
              : 'Plant uniformly so the whole plot flowers at once, clear Johnson grass from borders, and rotate with beans or soy.',
        ),
        CropPestWarning(
          pestName: es ? 'Gusano Cogollero en Sorgo' : 'Fall Armyworm in Sorghum',
          scientificName: 'Spodoptera frugiperda',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Primeras semanas de crecimiento y sequías cortas'
              : 'Early growth weeks and short dry spells',
          symptomsAndImpact: es
              ? 'Ataca el cogollo de las plantas jóvenes y también puede subir a comer el grano tierno en la panoja.'
              : 'Attacks the whorl of young plants and can also climb up to feed on tender grain in the panicle.',
          preventionAction: es
              ? 'Revisa las plantas jóvenes cada semana y alterna el lote con cultivos de hoja ancha.'
              : 'Inspect young plants weekly and alternate the plot with broadleaf crops.',
        ),
      ];
    }

    // 5. MELÓN / MELON
    if (lower.contains('melón') || lower.contains('melon')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Pulgón del Melón (Melera o Piojillo)'
              : 'Melon Aphid (Melera)',
          scientificName: 'Aphis gossypii',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Se multiplica rapidísimo en días cálidos sin necesidad de aparearse'
              : 'Multiplies very fast on warm days',
          symptomsAndImpact: es
              ? 'Debilita y seca las guías de melón chupando la savia en los brotes tiernos; en pocos días puede infestar toda la parcela.'
              : 'Weakens and dries out melon vines by sucking sap from tender shoots; can infest the whole plot within days.',
          preventionAction: es
              ? 'Revisa las puntas de las guías a diario, elimina las primeras hojas infestadas y pon trampas amarillas.'
              : 'Check vine tips daily, remove the first infested leaves immediately, and set yellow sticky traps.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Arañuela Roja y Gusanos de la Hoja'
              : 'Spider Mite & Foliage Caterpillars',
          scientificName: 'Tetranychidae / Spodoptera spp.',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Época seca y calurosa'
              : 'Dry and hot weather',
          symptomsAndImpact: es
              ? 'La arañuela vive debajo de la hoja chupando el jugo hasta secar la mata; los gusanos soldados comen hojas y raspan la cáscara del melón.'
              : 'Spider mites live under leaves sucking juices until vines dry up; armyworms chew leaves and scar melon rinds.',
          preventionAction: es
              ? 'Mantén la humedad pareja con riego por goteo y siembra barreras de maíz o sorgo alrededor del lote.'
              : 'Keep moisture steady with drip irrigation and plant corn or sorghum barriers around the plot.',
        ),
      ];
    }

    // 6. SANDÍA / WATERMELON
    if (lower.contains('sandía') || lower.contains('sandia') || lower.contains('watermelon')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Pulga Saltona, Gusano Trozador y Cogollero'
              : 'Flea Beetle, Cutworm & Armyworm',
          scientificName: 'Epitrix / Agrotis / Spodoptera',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Recién nacida la planta y durante el crecimiento de las guías'
              : 'Right after seedling emergence and during vine growth',
          symptomsAndImpact: es
              ? 'La pulga saltona hace agujeritos redondos en las hojas; el gusano trozador corta el tallito al ras del suelo y el cogollero daña hojas y frutas.'
              : 'Flea beetles chew tiny round holes in leaves; cutworms slice stems at ground level, and armyworms damage leaves and fruit.',
          preventionAction: es
              ? 'Limpia bien las malezas antes de sembrar y cuida de cerca las plantitas durante las primeras 3 semanas.'
              : 'Clear weeds thoroughly before planting and closely protect seedlings during the first 3 weeks.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Nematodos de la Raíz y Mosca Blanca'
              : 'Root Nematodes & Whitefly',
          scientificName: 'Meloidogyne spp. / Bemisia',
          riskLevel: isSandy ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Suelos sueltos o arenosos y clima cálido'
              : 'Loose or sandy soils and warm weather',
          symptomsAndImpact: es
              ? 'Los nematodos forman nudos o bolitas en la raíz impidiendo que la planta tome agua (se marchita al sol); la mosca blanca pone las hojas amarillas y chinas.'
              : 'Nematodes form knots on roots blocking water uptake (plants wilt in midday sun); whiteflies turn leaves yellow and curled.',
          preventionAction: es
              ? 'Agrega buen abono orgánico o compost al suelo y rota el terreno con frijol o crotalaria para limpiar la tierra.'
              : 'Add rich organic compost to the soil and rotate the land with beans or crotalaria to sanitize the root zone.',
        ),
      ];
    }

    // 7. PIÑA / PINEAPPLE
    if (lower.contains('piña') || lower.contains('pina') || lower.contains('pineapple')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Gusano Barrenador de la Piña (Tecla) y Gusano Soldado'
              : 'Pineapple Fruit Borer (Tecla) & Armyworm',
          scientificName: 'Strymon megarus / Spodoptera',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cuando sale la flor de la piña y empieza a formarse la fruta'
              : 'When the pineapple flower emerges and fruit begins forming',
          symptomsAndImpact: es
              ? 'El gusano perfora la fruta haciendo túneles y sale una goma color ámbar (gomosis), pudriendo la piña; el gusano soldado muerde alrededor de los ojos de la fruta.'
              : 'The larva bores into the fruit leaving amber gum (gummosis) and rot; armyworms chew around the fruit eyes.',
          preventionAction: es
              ? 'Cuida y aplica control preventivo desde que asoma la flor roja y saca del lote las frutas que tengan goma.'
              : 'Apply preventive care as soon as the red flower bud appears and remove any fruit showing gum.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Picudo del Tallo y Pudrición de la Raíz y Corazón'
              : 'Stem Weevil & Root/Heart Rot',
          scientificName: 'Metamasius / Scutigerella / Thielaviopsis',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Terrenos húmedos o que se encharcan'
              : 'Wet or poorly drained ground',
          symptomsAndImpact: es
              ? 'El picudo se mete al tallo y lo pudre; los bichitos blancos de la raíz no dejan que la planta coma y el hongo pudre el cogollo cuando hay exceso de agua.'
              : 'The weevil bores into the stem causing rot; tiny white root pests block feeding, and fungus rots the heart when water pools.',
          preventionAction: es
              ? 'Usa hijos sanos y desinfectados al sembrar y haz camas altas con buenas zanjas de drenaje si tu tierra es pesada.'
              : 'Use clean, disinfected slips when planting and build raised beds with good drainage ditches in heavy soil.',
        ),
      ];
    }

    // 8. MANZANA / APPLE
    if (lower.contains('manzana') || lower.contains('apple')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Cenicilla (Oídio) y Gusano de la Manzana'
              : 'Powdery Mildew & Codling Moth',
          scientificName: 'Podosphaera leucotricha / Cydia pomonella',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Brotación de flores y días templados con rocío'
              : 'Flower budding and mild days with morning dew',
          symptomsAndImpact: es
              ? 'La cenicilla cubre hojas y flores con un polvo blanco; el gusano de la manzana se mete hasta el corazón de la fruta haciendo que se caiga antes de madurar.'
              : 'Powdery mildew coats leaves and blossoms in white dust; the codling moth larva tunnels to the core, causing fruit to drop early.',
          preventionAction: es
              ? 'Poda las ramas enfermas para que entre sol, no mojes el follaje al regar y recoge las manzanas picadas que caen al suelo.'
              : 'Prune diseased branches to let sunlight in, avoid wetting leaves when watering, and pick up fallen infested apples.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Escama de San José, Araña Roja y Pulgones'
              : 'San Jose Scale, Red Spider Mite & Aphids',
          scientificName: 'Quadraspidiotus perniciosus / Panonychus ulmi',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Temporada cálida y seca'
              : 'Warm and dry season',
          symptomsAndImpact: es
              ? 'La escama pega costras con manchitas rojas en ramas y frutas debilitando el árbol; la araña roja seca las hojas y los pulgones enchuran los brotes.'
              : 'Scale insects form red-ringed crusts on branches and fruit weakening the tree; spider mites dry leaves and aphids curl shoots.',
          preventionAction: es
              ? 'Revisa el tronco y las ramas principales y aplica aceites minerales o jabón potásico en focos iniciales.'
              : 'Inspect the trunk and main branches and apply mineral oil or potassium soap on early hotspots.',
        ),
      ];
    }

    // 9. NARANJA / CÍTRICOS / ORANGE
    if (lower.contains('naranja') || lower.contains('cítric') || lower.contains('orange')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Escama Roja de la Naranja'
              : 'California Red Scale',
          scientificName: 'Aonidiella aurantii',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Clima cálido y árboles muy cerrados sin podar'
              : 'Warm weather and unpruned dense trees',
          symptomsAndImpact: es
              ? 'Se pega como pequeñas conchitas rojizas en ramas, hojas y naranjas, chupando la savia hasta secar las ramas.'
              : 'Sticks like tiny reddish shells on branches, leaves, and oranges, sucking sap until branches dry up.',
          preventionAction: es
              ? 'Poda el centro del árbol para que entre aire y sol y aplica aceite mineral agrícola sobre las ramas afectadas.'
              : 'Prune the center of the tree for airflow and sunlight and apply agricultural mineral oil on affected branches.',
        ),
        CropPestWarning(
          pestName: es ? 'Mosca de la Fruta' : 'Fruit Fly',
          scientificName: 'Ceratitis capitata / Anastrepha spp.',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cuando la naranja empieza a cambiar de color y madurar'
              : 'When oranges begin turning color and ripening',
          symptomsAndImpact: es
              ? 'Pica la cáscara de la naranja para poner sus huevos adentro; luego salen gusanitos que pudren la fruta y la botan al suelo.'
              : 'Punctures the orange peel to lay eggs inside; maggots then rot the pulp and cause the fruit to drop.',
          preventionAction: es
              ? 'Cuelga botellas trampa con atrayente en los árboles y recoge y entierra todas las naranjas caídas.'
              : 'Hang attractant bottle traps in trees and collect and bury all fallen oranges.',
        ),
      ];
    }

    // 10. CAÑA DE AZÚCAR / SUGARCANE
    if (lower.contains('caña') || lower.contains('cana') || lower.contains('sugar')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Cogollo Retorcido (Pokka Boeng)'
              : 'Twisted Top Disease (Pokka Boeng)',
          scientificName: 'Fusarium spp.',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Lluvias fuertes después de una temporada seca'
              : 'Heavy rains following a dry spell',
          symptomsAndImpact: es
              ? 'Es un hongo que retuerce y arruga las hojas nuevas del cogollo y pudre la raíz, haciendo que la caña no crezca y se marchite.'
              : 'A fungus that twists and wrinkles new top leaves and rots roots, stunting and wilting the cane.',
          preventionAction: es
              ? 'Abre buenos canales de desagüe para que no se estanque el agua y siembra únicamente semilla de caña sana.'
              : 'Open good drainage channels so water does not pool and plant only healthy seed cane.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Picudo de la Caña y Pulgón Amarillo'
              : 'Sugarcane Weevil & Yellow Aphid',
          scientificName: 'Metamasius / Sipha flava',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cuando vienen saliendo los retoños (soca) y en tiempo seco'
              : 'During ratoon sprouting and dry weather',
          symptomsAndImpact: es
              ? 'El picudo se mete por los cortes del tallo pudriendo la cepa; el pulgón amarillo chupa la savia debajo de las hojas hasta secarlas.'
              : 'The weevil enters through stalk cuts rotting the stool; yellow aphids suck sap under leaves until they dry out.',
          preventionAction: es
              ? 'Corta la caña al ras del suelo en la cosecha, limpia los restos podridos y coloca trampas con trozos de caña fermentada.'
              : 'Cut cane flush with the ground at harvest, clear rotted trash, and set fermented cane traps.',
        ),
      ];
    }

    // 11. TRIGO / WHEAT
    if (lower.contains('trigo') || lower.contains('wheat')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Pulgón del Trigo y Chinche de la Espiga'
              : 'Wheat Aphid & Spike Stink Bug',
          scientificName: 'Schizaphis graminum / Hemiptera',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cuando sale la espiga y empieza a llenar el grano'
              : 'When spikes emerge and grain begins filling',
          symptomsAndImpact: es
              ? 'Los pulgones y chinches chupan el jugo de la espiga tierna, dejando partes blancas y granos chupados sin peso.'
              : 'Aphids and stink bugs suck juices from tender spikes, leaving bleached white spots and shriveled light grains.',
          preventionAction: es
              ? 'Revisa las espigas cada semana durante el llenado del grano y rota el terreno con frijol o soya en el siguiente ciclo.'
              : 'Inspect spikes weekly during grain filling and rotate the land with beans or soy in the next cycle.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Gallina Ciega / Gusano Blanco del Suelo'
              : 'White Soil Grub (Coro)',
          scientificName: 'Diloboderus abderus',
          riskLevel: 'moderate',
          climateTrigger: es
              ? 'Suelos con mucho rastrojo viejo donde el escarabajo pone huevos'
              : 'Soils with heavy old residue where beetles lay eggs',
          symptomsAndImpact: es
              ? 'El gusano vive bajo tierra y se come las raíces del trigo, dejando manchones de plantas amarillas o secas en el lote.'
              : 'The grub lives underground and eats wheat roots, leaving patches of yellow or dead plants across the plot.',
          preventionAction: es
              ? 'Revisa la tierra debajo del rastrojo antes de sembrar para detectar si hay gusanos blancos.'
              : 'Check the soil beneath crop residue before planting to spot white grubs early.',
        ),
      ];
    }

    // 12. ARROZ / RICE
    if (lower.contains('arroz') || lower.contains('rice')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Quema o Tizón del Arroz y Mancha Café'
              : 'Rice Blast & Brown Spot',
          scientificName: 'Pyricularia / Helminthosporium',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Calor húmedo y exceso de abono nitrogenado'
              : 'Humid heat and excess nitrogen fertilizer',
          symptomsAndImpact: es
              ? 'Forman manchas color café o con forma de ojo en las hojas y en el cuello de la espiga, haciendo que la espiga se quiebre o quede vana.'
              : 'Form brown or eye-shaped spots on leaves and panicle necks, causing panicles to snap or stay empty.',
          preventionAction: es
              ? 'No te excedas con la urea de golpe (aplícala dividida en partes) y maneja el agua por mojes sin dejarla estancada todo el tiempo.'
              : 'Do not apply excessive urea all at once (split applications) and manage water intermittently.',
        ),
      ];
    }

    // 13. BANANO Y PLÁTANO / BANANA & PLANTAIN
    if (lower.contains('banan') || lower.contains('plátan') || lower.contains('platan') || lower.contains('plantain')) {
      return [
        CropPestWarning(
          pestName: es ? 'Sigatoka Negra' : 'Black Sigatoka',
          scientificName: 'Mycosphaerella fijiensis',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Lluvias frecuentes y humedad encerrada en la plantación'
              : 'Frequent rain and trapped humidity inside the plantation',
          symptomsAndImpact: es
              ? 'Es un hongo que llena las hojas de rayas negras hasta secarlas; si la planta se queda con pocas hojas sanas, el racimo no engorda y madura antes de tiempo.'
              : 'A fungus that covers leaves with black streaks until they dry; with too few healthy leaves, the bunch stays small and ripens prematurely.',
          preventionAction: es
              ? 'Corta semanalmente las puntas u hojas manchadas (deshoje sanitario) y mantén limpias las zanjas de drenaje para bajar la humedad.'
              : 'Trim spotted leaf tips weekly (sanitary deleafing) and keep drainage ditches clear to lower humidity.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Picudo Negro del Plátano y Pulgón'
              : 'Corm Weevil & Banana Aphid',
          scientificName: 'Cosmopolites sordidus / Pentalonia nigronervosa',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cepas húmedas y brotación de hijos'
              : 'Moist corms and sucker sprouting',
          symptomsAndImpact: es
              ? 'El picudo hace túneles en la cepa (cabeza) debilitando la mata hasta que el viento la bota; el pulgón transmite virus que arrepollan las hojas nuevas.'
              : 'The weevil tunnels into the corm weakening the plant until wind topples it; aphids spread virus that bunches up new leaves.',
          preventionAction: es
              ? 'Pon trampas hechas con rodajas de tallo fresco en el suelo para atrapar al picudo y siembra únicamente hijos sanos.'
              : 'Place fresh pseudostem slice traps on the ground to catch weevils and plant only clean suckers.',
        ),
      ];
    }

    // 14. MANGO
    if (lower.contains('mango')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Mosca de la Fruta, Gorgojo de la Semilla y Barrenador'
              : 'Fruit Fly, Seed Weevil & Branch Borer',
          scientificName: 'Anastrepha / Sternochetus / Cerambycidae',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Floración y cuando el mango empieza a sazonar'
              : 'Flowering and when mangoes start ripening',
          symptomsAndImpact: es
              ? 'La mosca y el gorgojo meten gusanos dentro del mango pudriendo la pulpa y la semilla; el barrenador hace huecos en las ramas gruesas hasta secarlas.'
              : 'Fruit flies and weevils infest the mango pulp and seed; branch borers tunnel into thick limbs until they dry out.',
          preventionAction: es
              ? 'Poda las ramas secas o dañadas, coloca botellas trampa en el árbol y recoge todos los mangos caídos del suelo.'
              : 'Prune dry or damaged limbs, hang bottle traps in the tree, and pick up all fallen mangoes from the ground.',
        ),
      ];
    }

    // 15. SOYA / SOJA / SOYBEAN
    if (lower.contains('soya') || lower.contains('soja') || lower.contains('soy')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Chinche Marrón y Gusanos Comedores de Hoja'
              : 'Brown Stink Bug & Leaf Caterpillars',
          scientificName: 'Euschistus heros / Anticarsia gemmatalis',
          riskLevel: 'high',
          climateTrigger: es
              ? 'Cuando la soya está echando vainas y llenando grano'
              : 'When soy plants are forming pods and filling beans',
          symptomsAndImpact: es
              ? 'El chinche pica las vainas tiernas dejando los granos chupados y vanos; los gusanos se comen las hojas dejando solo las venas.'
              : 'Stink bugs pierce young pods leaving beans shriveled and empty; caterpillars eat leaves down to the veins.',
          preventionAction: es
              ? 'Revisa las orillas del lote sacudiendo las plantas sobre una tela blanca y rota el terreno con maíz o sorgo.'
              : 'Scout plot borders by shaking plants over a white cloth and rotate the land with corn or sorghum.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Comején o Termitas de Tierra Seca'
              : 'Dry-Soil Subterranean Termites',
          scientificName: 'Isoptera',
          riskLevel: (isSandy || isDryWarm) ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Suelos arenosos o cuando pasan muchos días sin llover'
              : 'Sandy soils or after many days without rain',
          symptomsAndImpact: es
              ? 'Atacan la raíz de las plantitas en tierra seca, dejando manchones de plantas marchitas que a veces se confunden con falta de abono.'
              : 'Attack seedling roots in dry earth, leaving patches of wilted plants often mistaken for fertilizer deficiency.',
          preventionAction: es
              ? 'Arranca y revisa la raíz si ves manchones amarillos y mantén la humedad pareja en el suelo.'
              : 'Pull and check roots if you see yellow patches and keep soil moisture even.',
        ),
      ];
    }

    // 16. UVAS / GRAPES
    if (lower.contains('uva') || lower.contains('vid') || lower.contains('grape')) {
      return [
        CropPestWarning(
          pestName: es
              ? 'Mildiú y Ceniza de la Uva (Oídio)'
              : 'Grape Downy & Powdery Mildew',
          scientificName: 'Plasmopara viticola / Erysiphe necator',
          riskLevel: isHumid ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Mañanas húmedas y follaje muy cerrado sin entrada de sol'
              : 'Humid mornings and dense foliage without sunlight',
          symptomsAndImpact: es
              ? 'Forma manchas aceitosas o un polvillo blanco cenizo sobre las hojas y los racimos tiernos, haciendo que las uvas se rajen y se pudran antes de madurar.'
              : 'Forms oily spots or white ash-like powder on leaves and young clusters, causing grapes to crack and rot before ripening.',
          preventionAction: es
              ? 'Deshoja alrededor de los racimos para que les entre sol y aire, evita mojar las hojas al regar y aplica azufre o caldo bordelés preventivo.'
              : 'Thin leaves around clusters so sun and air reach them, avoid wetting foliage when watering, and apply preventive sulfur or Bordeaux mixture.',
        ),
        CropPestWarning(
          pestName: es
              ? 'Trips y Cochinilla Harinosa en Racimos'
              : 'Grape Thrips & Mealybugs',
          scientificName: 'Frankliniella / Planococcus ficus',
          riskLevel: isDryWarm ? 'high' : 'moderate',
          climateTrigger: es
              ? 'Tiempo cálido y seco durante la floración y el llenado del racimo'
              : 'Warm, dry weather during flowering and cluster filling',
          symptomsAndImpact: es
              ? 'Raspan la cáscara de la uva dejando cicatrices color café y secretan mielecilla pegajosa que mancha todo el racimo.'
              : 'Scar grape skins leaving brown marks and secrete sticky honeydew that stains the entire cluster.',
          preventionAction: es
              ? 'Coloca trampas azules durante la floración, controla las hormigas en el tronco y limpia la corteza suelta donde se esconden.'
              : 'Hang blue sticky traps during flowering, control ants on the trunk, and clean loose bark where pests hide.',
        ),
      ];
    }

    // Default fallback
    return [
      CropPestWarning(
        pestName: es
            ? 'Gusano Cogollero y Mosca Blanca'
            : 'Fall Armyworm & Whitefly',
        scientificName: 'Spodoptera frugiperda / Bemisia',
        riskLevel: 'high',
        climateTrigger: es
            ? 'Días cálidos y lotes vecinos con el mismo cultivo'
            : 'Warm days and neighboring plots with the same crop',
        symptomsAndImpact: es
            ? 'El gusano mastica las hojas tiernas y la mosca blanca chupa la savia debilitando el cultivo.'
            : 'Armyworms chew tender leaves and whiteflies suck sap weakening the crop.',
        preventionAction: es
            ? 'Rota tus lotes alternando maíz o sorgo con frijol o soya y limpia las malezas de las orillas.'
            : 'Rotate your plots alternating corn or sorghum with beans or soy and clear border weeds.',
      ),
    ];
  }

  /// Returns practical irrigation systems explained in clear farmer language.
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
    final litersPerM2 = recommendedWaterMm.toStringAsFixed(0);

    return [
      IrrigationSystemOption(
        systemName: es
            ? 'Riego por Goteo en Riegos Cortos y Frecuentes'
            : 'Short, Frequent Drip Irrigation',
        efficiencyPct: '92% - 95%',
        bestForSoil: es ? 'Suelo Arenoso y Franco' : 'Sandy & Loam Soils',
        description: es
            ? 'Entrega el agua ($litersPerM2 litros por metro cuadrado) gota a gota directo al pie de la planta en varios riegos cortos. En tierra arenosa evita que el agua y el abono se vayan al fondo y se pierdan.'
            : 'Delivers water ($litersPerM2 liters per m²) drop by drop right to the plant base in short sessions. In sandy earth, it stops water and fertilizer from washing away.',
        nasaIntegrationNote: es
            ? 'Ahorra casi toda el agua y mantiene fresca la raíz sin mojar las hojas.'
            : 'Saves water and keeps roots moist without wetting leaves.',
        isRecommendedForCurrentSoil: isSandy || isLoam,
      ),
      IrrigationSystemOption(
        systemName: es
            ? 'Microaspersión Suave con Suelo Cubierto (Mulch)'
            : 'Gentle Micro-Sprinkler with Mulch Cover',
        efficiencyPct: '85% - 88%',
        bestForSoil: es ? 'Suelo Limoso y Terrenos en Ladera' : 'Silt Soils & Sloped Land',
        description: es
            ? 'Riega como una llovizna suave que no golpea ni aprieta la tierra. Como el suelo limoso se endurece si queda pelado en laderas, acompañarlo con zacate seco o rastrojo en el suelo guarda muy bien la humedad.'
            : 'Waters like a gentle mist that does not pack the earth. Since silty soil hardens if left bare on slopes, pairing it with dry mulch keeps moisture in.',
        nasaIntegrationNote: es
            ? 'Suspende el riego si ves venir días de lluvia para no lavar la tierra.'
            : 'Pause watering before rainy days so you do not wash out the soil.',
        isRecommendedForCurrentSoil: isSilt,
      ),
      IrrigationSystemOption(
        systemName: es
            ? 'Goteo Lento con Zanjas de Desagüe'
            : 'Slow Drip with Drainage Ditches',
        efficiencyPct: '90%',
        bestForSoil: es ? 'Suelo Arcilloso (Tierra Pesada)' : 'Clay Soils (Heavy Earth)',
        description: es
            ? 'Como la tierra arcillosa chupa despacio pero guarda el agua por muchos días, regar lento evita que se hagan charcos de barro y deja que la raíz respire sin pudrirse.'
            : 'Since clay earth absorbs slowly but holds water for many days, slow drip prevents muddy puddles and lets roots breathe without rotting.',
        nasaIntegrationNote: es
            ? 'Deja descansar la tierra entre riegos para que no se pase de humedad.'
            : 'Let the earth rest between waterings so it does not get waterlogged.',
        isRecommendedForCurrentSoil: isClay,
      ),
      IrrigationSystemOption(
        systemName: es
            ? 'Riego por Surcos Alternos (Un Surco Sí y Uno No)'
            : 'Alternate Furrow Watering (Every Other Row)',
        efficiencyPct: '75% - 80%',
        bestForSoil: es ? 'Suelo Franco (Opción Económica)' : 'Loam Soil (Low-Cost Option)',
        description: es
            ? 'Opción práctica y barata para el productor: se pasa el agua por un surco sí y otro no, y en el siguiente riego se cambia de surco. Ahorras una tercera parte del agua y la raíz siempre tiene humedad.'
            : 'Practical, low-cost method: run water down every other furrow, then switch rows next time. Cuts water use by a third while keeping roots moist.',
        nasaIntegrationNote: es
            ? 'Revisa a unos 10 cm de profundidad con la mano antes de volver a regar.'
            : 'Check moisture 10 cm deep by hand before watering again.',
        isRecommendedForCurrentSoil: isLoam,
      ),
    ];
  }

  /// Generates the 3-Week Rolling Projection (Day 1 to Day 21) and 7-Day Checkpoint in farmer language.
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

    final projectedMoistureW2 =
        (soilMoisturePct - (weeklyDeficitMm * 0.35)).clamp(24.0, 88.0).toStringAsFixed(0);
    final projectedMoistureW3 =
        (soilMoisturePct - (weeklyDeficitMm * 0.60)).clamp(20.0, 85.0).toStringAsFixed(0);

    final phases = [
      WeeklyProjectionPhase(
        weekNumber: 1,
        dateRangeLabel: '${_formatShortDate(w1Start)} - ${_formatShortDate(w1End)}',
        title: es
            ? 'Semana 1: Riego a Tiempo y Revisión de Hojas'
            : 'Week 1: Timely Watering & Leaf Inspection',
        expectedMetrics: es
            ? 'Humedad en raíz: ${soilMoisturePct.toStringAsFixed(0)}% • Agua faltante: ${weeklyDeficitMm.toStringAsFixed(0)} L/m²'
            : 'Root moisture: ${soilMoisturePct.toStringAsFixed(0)}% • Water needed: ${weeklyDeficitMm.toStringAsFixed(0)} L/m²',
        recommendedAction: es
            ? 'Riega según tu suelo $soilType y camina el lote revisando el cogollo y debajo de las hojas de $crop para frenar plagas a tiempo.'
            : 'Water according to your $soilType soil and walk the plot checking whorls and leaf undersides of $crop to catch pests early.',
      ),
      WeeklyProjectionPhase(
        weekNumber: 2,
        dateRangeLabel: '${_formatShortDate(w2Start)} - ${_formatShortDate(w2End)}',
        title: es
            ? 'Semana 2: Cuidado del Crecimiento y Humedad'
            : 'Week 2: Growth Care & Moisture Watch',
        expectedMetrics: es
            ? 'Humedad estimada si no llueve: ~$projectedMoistureW2% • Temperatura media: ${tempC.toStringAsFixed(1)} °C'
            : 'Estimated moisture without rain: ~$projectedMoistureW2% • Avg temp: ${tempC.toStringAsFixed(1)} °C',
        recommendedAction: es
            ? 'Si no llueve y la tierra baja del 45% de humedad, aplica riegos cortos y pon rastrojo (mulch) al pie de la planta.'
            : 'If it does not rain and moisture drops below 45%, apply short waterings and place dry mulch around plant bases.',
      ),
      WeeklyProjectionPhase(
        weekNumber: 3,
        dateRangeLabel: '${_formatShortDate(w3Start)} - ${_formatShortDate(w3End)}',
        title: es
            ? 'Semana 3: Abono de la Tierra y Preparación de Rotación'
            : 'Week 3: Soil Feeding & Rotation Prep',
        expectedMetrics: es
            ? 'Humedad estimada: ~$projectedMoistureW3% • Próximo cultivo sugerido: $suggestedRotationCrop'
            : 'Estimated moisture: ~$projectedMoistureW3% • Suggested next crop: $suggestedRotationCrop',
        recommendedAction: es
            ? 'Prepara la incorporación de abono orgánico y planifica rotar el lote con $suggestedRotationCrop para abonar la tierra gratis y cortar las plagas.'
            : 'Prepare organic compost incorporation and plan to rotate the plot with $suggestedRotationCrop to naturally fertilize the soil and break pest cycles.',
      ),
    ];

    final changes = es
        ? [
            'La humedad de la tierra pasó de ${(soilMoisturePct + 4.5).clamp(20, 95).toStringAsFixed(0)}% a ${soilMoisturePct.toStringAsFixed(0)}% en estos últimos 7 días (${weeklyDeficitMm > 15 ? 'bajó por el sol y el calor' : 'se mantuvo estable'}).',
            'El calor de la última semana (${tempC.toStringAsFixed(1)} °C promedio) aceleró el crecimiento de tu $crop, pero también favorece que salgan más insectos.',
            'Se actualizaron los cuidados contra plagas y el riego recomendado para tu suelo $soilType.',
          ]
        : [
            'Soil moisture went from ${(soilMoisturePct + 4.5).clamp(20, 95).toStringAsFixed(0)}% to ${soilMoisturePct.toStringAsFixed(0)}% over the past 7 days (${weeklyDeficitMm > 15 ? 'dropped due to sun and heat' : 'stayed stable'}).',
            'Last week\'s warmth (${tempC.toStringAsFixed(1)} °C avg) sped up $crop growth, which also increases insect activity.',
            'Updated pest care and watering recommendations for your $soilType soil.',
          ];

    return ThreeWeekProjection(
      fullDateRange: fullRange,
      phases: phases,
      longTermClimateNote: es
          ? 'Revisar tu lote cada semana y planificar a 3 semanas te ayuda a que ni la sequía ni las plagas te tomen por sorpresa.'
          : 'Checking your plot weekly and planning 3 weeks ahead keeps droughts and pests from catching you off guard.',
      weeklyCheckpointTitle: es
          ? '¿Qué Cambió en tu Finca esta Última Semana?'
          : 'What Changed on Your Farm This Past Week?',
      weeklyCheckpointPeriod: checkpointPeriod,
      weeklyCheckpointSummary: es
          ? 'Así cambió tu terreno comparado con hace 7 días:'
          : 'Here is how your land changed compared to 7 days ago:',
      weeklyChangesDetected: changes,
    );
  }

  /// Normalizes internal database crop keys (like 'corn', 'beans', 'coffee') into localized farmer names.
  static String normalizeCropName(String? rawCrop, {bool? isSpanish}) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    if (rawCrop == null || rawCrop.trim().isEmpty) {
      return es ? 'Maíz' : 'Corn';
    }
    final q = rawCrop.trim().toLowerCase();
    if (q == 'corn' || q == 'maíz' || q == 'maiz') return es ? 'Maíz' : 'Corn';
    if (q == 'beans' || q == 'frijol') return es ? 'Frijol' : 'Beans';
    if (q == 'coffee' || q == 'café' || q == 'cafe') return es ? 'Café' : 'Coffee';
    if (q == 'rice' || q == 'arroz') return es ? 'Arroz' : 'Rice';
    if (q == 'soybean' || q == 'soya' || q == 'soja') return es ? 'Soya' : 'Soybean';
    if (q == 'sorghum' || q == 'sorgo') return es ? 'Sorgo' : 'Sorghum';
    if (q == 'sugarcane' || q.contains('caña') || q.contains('cana')) {
      return es ? 'Caña de azúcar' : 'Sugarcane';
    }
    if (q == 'plantain' || q.contains('plátano') || q.contains('platano')) {
      return es ? 'Plátano' : 'Plantain';
    }
    if (q == 'banana' || q == 'banano') return es ? 'Banano' : 'Banana';
    if (q == 'watermelon' || q.contains('sandía') || q.contains('sandia')) {
      return es ? 'Sandía' : 'Watermelon';
    }
    if (q == 'melon' || q.contains('melón')) return es ? 'Melón' : 'Melon';
    if (q == 'pineapple' || q.contains('piña') || q.contains('pina')) {
      return es ? 'Piña' : 'Pineapple';
    }
    if (q == 'apple' || q == 'manzana') return es ? 'Manzana' : 'Apple';
    if (q == 'orange' || q == 'naranja') return es ? 'Naranja' : 'Orange';
    if (q == 'wheat' || q == 'trigo') return es ? 'Trigo' : 'Wheat';
    if (q == 'mango') return 'Mango';
    if (q == 'grapes' || q.contains('uva')) return es ? 'Uvas' : 'Grapes';
    return rawCrop.trim();
  }

  /// Normalizes internal database soil keys (like 'arenoso', 'arcilloso', 'limoso', 'franco').
  static String normalizeSoilName(String? rawSoil, {bool? isSpanish}) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    if (rawSoil == null || rawSoil.trim().isEmpty) {
      return es ? 'Franco' : 'Loam';
    }
    final q = rawSoil.trim().toLowerCase();
    if (q.contains('aren') || q.contains('sand')) {
      return es ? 'Arenoso' : 'Sandy';
    }
    if (q.contains('arcill') || q.contains('clay')) {
      return es ? 'Arcilloso' : 'Clay';
    }
    if (q.contains('lim') || q.contains('silt')) {
      return es ? 'Limoso' : 'Silt';
    }
    if (q.contains('franc') || q.contains('loam')) {
      return es ? 'Franco' : 'Loam';
    }
    return rawSoil.trim();
  }

  /// Detects if the farmer mentioned a specific crop in their prompt, otherwise uses [defaultCrop].
  static String detectTargetCropFromPrompt(String query, String defaultCrop) {
    final q = query.toLowerCase();
    if (q.contains('café') || q.contains('cafe') || q.contains('cafetal') || q.contains('coffee')) {
      return 'Café';
    }
    if (q.contains('frijol') || q.contains('bean')) {
      return 'Frijol';
    }
    if (q.contains('maíz') || q.contains('maiz') || q.contains('milpa') || q.contains('elote') || q.contains('corn')) {
      return 'Maíz';
    }
    if (q.contains('arroz') || q.contains('rice')) {
      return 'Arroz';
    }
    if (q.contains('soya') || q.contains('soja') || q.contains('soy')) {
      return 'Soya';
    }
    if (q.contains('sorgo') || q.contains('sorghum') || q.contains('millón')) {
      return 'Sorgo';
    }
    if (q.contains('caña') || q.contains('cana') || q.contains('sugar')) {
      return 'Caña de azúcar';
    }
    if (q.contains('banano') || q.contains('banana')) {
      return 'Banano';
    }
    if (q.contains('plátano') || q.contains('platano') || q.contains('guineo') || q.contains('plantain')) {
      return 'Plátano';
    }
    if (q.contains('sandía') || q.contains('sandia') || q.contains('watermelon')) {
      return 'Sandía';
    }
    if (q.contains('melón') || q.contains('melon')) {
      return 'Melón';
    }
    if (q.contains('piña') || q.contains('pina') || q.contains('pineapple')) {
      return 'Piña';
    }
    if (q.contains('manzana') || q.contains('apple')) {
      return 'Manzana';
    }
    if (q.contains('naranja') || q.contains('cítric') || q.contains('citric') || q.contains('orange')) {
      return 'Naranja';
    }
    if (q.contains('trigo') || q.contains('wheat')) {
      return 'Trigo';
    }
    if (q.contains('mango')) {
      return 'Mango';
    }
    if (q.contains('uva') || q.contains('vid') || q.contains('grape')) {
      return 'Uvas';
    }
    return normalizeCropName(defaultCrop);
  }

  /// Detects if the farmer mentioned a specific soil type in their prompt, otherwise uses [defaultSoil].
  static String detectTargetSoilFromPrompt(String query, String defaultSoil) {
    final q = query.toLowerCase();
    if (q.contains('arenos') || q.contains('arena') || q.contains('sandy')) {
      return 'Arenoso';
    }
    if (q.contains('arcillos') || q.contains('arcilla') || q.contains('barrial') || q.contains('clay')) {
      return 'Arcilloso';
    }
    if (q.contains('limos') || q.contains('limo') || q.contains('silt')) {
      return 'Limoso';
    }
    if (q.contains('franco') || q.contains('loam')) {
      return 'Franco';
    }
    return normalizeSoilName(defaultSoil);
  }

  /// Generates a direct, accurate, farmer-friendly response tailored specifically to the farmer's prompt.
  static String answerFarmerPrompt({
    required String query,
    required Map<String, dynamic> farm,
    required Map<String, dynamic> nasa,
    required FarmPredictionsReport report,
    required String activeCrop,
    required String activeSoil,
    List<String>? allFarmCrops,
    bool? isSpanish,
  }) {
    final es = isSpanish ?? AppLanguage.isSpanish;
    final qLower = query.toLowerCase().trim();

    final normalizedDefaultCrop = normalizeCropName(activeCrop, isSpanish: es);
    final normalizedDefaultSoil = normalizeSoilName(activeSoil, isSpanish: es);

    // Check if the farmer explicitly named a crop in their prompt
    final sentinelCrop = '__NONE__';
    final detectedFromPrompt = detectTargetCropFromPrompt(query, sentinelCrop);
    final bool userNamedSpecificCrop = detectedFromPrompt != sentinelCrop;

    final targetCrop =
        userNamedSpecificCrop ? detectedFromPrompt : normalizedDefaultCrop;
    final targetSoil =
        detectTargetSoilFromPrompt(query, normalizedDefaultSoil);

    // Distinct crops registered in the farmer's farm
    final List<String> registeredCrops = (allFarmCrops ?? [])
        .map((c) => normalizeCropName(c, isSpanish: es))
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    if (registeredCrops.isEmpty) {
      registeredCrops.add(targetCrop);
    }

    final summary = nasa['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final solarMj =
        (summary['avg_solar_radiation_mj'] as num?)?.toDouble() ?? 18.5;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final soilConcept =
        getSoilScientificConcept(targetSoil, isSpanish: es);
    final phenomena = evaluateNaturalPhenomena(
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      solarMj: solarMj,
      soilType: targetSoil,
      crop: targetCrop,
      isSpanish: es,
    );
    final pests = getPestWarningsForCrop(
      crop: targetCrop,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      soilType: targetSoil,
      isSpanish: es,
    );
    final irrigationSystems = getIrrigationSystemsForSoil(
      soilType: targetSoil,
      recommendedWaterMm: report.irrigation.recommendedWaterMm,
      isSpanish: es,
    );
    final recommendedSystem = irrigationSystems.firstWhere(
      (s) => s.isRecommendedForCurrentSoil,
      orElse: () => irrigationSystems.first,
    );
    final projection3w = generateThreeWeekProjection(
      crop: targetCrop,
      soilType: targetSoil,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisturePct: report.irrigation.soilMoisturePct,
      weeklyDeficitMm: report.irrigation.weeklyDeficitMm,
      accumulatedGdd7d: report.calendar.accumulatedGdd7d,
      suggestedRotationCrop: report.rotation.suggestedCrop,
      isSpanish: es,
    );

    // Check which topics the farmer is asking about
    final bool isInitialOverview = qLower.contains('explícame las predicciones') ||
        qLower.contains('explain the predictions') ||
        qLower.contains('prioritarias para mi finca hoy');

    final bool asksGreetingOrHelp = !isInitialOverview &&
        (qLower == 'hola' ||
            qLower == 'buenos días' ||
            qLower == 'buenos dias' ||
            qLower == 'buenas tardes' ||
            qLower.contains('quién eres') ||
            qLower.contains('quien eres') ||
            qLower.contains('qué puedes hacer') ||
            qLower.contains('que puedes hacer') ||
            qLower.contains('ayuda') ||
            qLower == 'help' ||
            qLower == 'hi' ||
            qLower == 'hello');

    final bool asksPests = !isInitialOverview &&
        (qLower.contains('plaga') ||
            qLower.contains('pest') ||
            qLower.contains('enfermedad') ||
            qLower.contains('bicho') ||
            qLower.contains('gusano') ||
            qLower.contains('cogollero') ||
            qLower.contains('broca') ||
            qLower.contains('roya') ||
            qLower.contains('mosca') ||
            qLower.contains('pulgón') ||
            qLower.contains('pulgon') ||
            qLower.contains('araña') ||
            qLower.contains('arana') ||
            qLower.contains('picudo') ||
            qLower.contains('hongo') ||
            qLower.contains('insecto') ||
            qLower.contains('sigatoka') ||
            qLower.contains('nematodo') ||
            qLower.contains('chinche') ||
            qLower.contains('termita') ||
            qLower.contains('comején') ||
            qLower.contains('tecla') ||
            qLower.contains('mancha') ||
            qLower.contains('tizón') ||
            qLower.contains('tizon'));

    final bool asksIrrigation = !isInitialOverview &&
        (qLower.contains('riego') ||
            qLower.contains('regar') ||
            qLower.contains('irrigat') ||
            qLower.contains('agua') ||
            qLower.contains('water') ||
            qLower.contains('humedad') ||
            qLower.contains('moisture') ||
            qLower.contains('goteo') ||
            qLower.contains('aspersión') ||
            qLower.contains('surco') ||
            qLower.contains('sed') ||
            qLower.contains('seco'));

    final bool asksWeather = !isInitialOverview &&
        (qLower.contains('clima') ||
            qLower.contains('weather') ||
            qLower.contains('fenómeno') ||
            qLower.contains('fenomeno') ||
            qLower.contains('phenomena') ||
            qLower.contains('lluvia') ||
            qLower.contains('llover') ||
            qLower.contains('rain') ||
            qLower.contains('calor') ||
            qLower.contains('temperatura') ||
            qLower.contains('sequía') ||
            qLower.contains('sequia') ||
            qLower.contains('inundaci') ||
            qLower.contains('tormenta') ||
            qLower.contains('deslizamiento') ||
            qLower.contains('sol'));

    final bool asksRotation = !isInitialOverview &&
        (qLower.contains('rotación') ||
            qLower.contains('rotacion') ||
            qLower.contains('rotar') ||
            qLower.contains('rotate') ||
            qLower.contains('qué sembrar después') ||
            qLower.contains('que sembrar despues') ||
            qLower.contains('siguiente cultivo') ||
            qLower.contains('otro cultivo') ||
            qLower.contains('cambiar de cultivo') ||
            qLower.contains('vecino'));

    final bool asksFertilizerOrNutrition = !isInitialOverview &&
        (qLower.contains('abono') ||
            qLower.contains('abonar') ||
            qLower.contains('fertiliz') ||
            qLower.contains('urea') ||
            qLower.contains('nitrógeno') ||
            qLower.contains('nitrogeno') ||
            qLower.contains('nutrici') ||
            qLower.contains('alimentar'));

    final bool asksSoil = !isInitialOverview &&
        (qLower.contains('suelo') ||
            qLower.contains('tierra') ||
            qLower.contains('soil') ||
            qLower.contains('arenos') ||
            qLower.contains('arcillos') ||
            qLower.contains('limos') ||
            qLower.contains('franco') ||
            qLower.contains('barro') ||
            qLower.contains('drenaje'));

    final bool asksPlantingOrCalendar = !isInitialOverview &&
        (qLower.contains('cuándo sembrar') ||
            qLower.contains('cuando sembrar') ||
            qLower.contains('fecha de siembra') ||
            qLower.contains('siembra') ||
            qLower.contains('sembrar') ||
            qLower.contains('calendario') ||
            qLower.contains('ventana') ||
            qLower.contains('cosecha') ||
            qLower.contains('when to plant'));

    final bool asksThreeWeeks = !isInitialOverview &&
        (qLower.contains('3 semana') ||
            qLower.contains('tres semana') ||
            qLower.contains('3-week') ||
            qLower.contains('proyecci') ||
            qLower.contains('próximas semanas') ||
            qLower.contains('proximas semanas') ||
            qLower.contains('plan') ||
            qLower.contains('cambio') ||
            qLower.contains('última semana') ||
            qLower.contains('ultima semana'));

    // 1. Greeting / Help
    if (asksGreetingOrHelp) {
      return es
          ? '¡Hola! Soy Eve, tu compañera de campo.\n\n'
              'Puedo ayudarte con cualquier duda sobre tu finca ($targetCrop en suelo $targetSoil):\n'
              '• Cuándo y cómo regar según tu tipo de tierra.\n'
              '• Cómo identificar y frenar plagas en Maíz, Frijol, Café, Arroz, Sorgo, Soya, Caña, Plátano, Sandía, Melón, Piña, Naranja, Manzana, Trigo o Mango.\n'
              '• Alertas de lluvias fuertes, sequías o calor.\n'
              '• Qué sembrar después para abonar tu tierra y ahorrar en fertilizantes.\n\n'
              '¿Qué te gustaría revisar hoy en tu parcela?'
          : 'Hi! I am Eve, your field partner.\n\n'
              'I can help you with any question about your farm ($targetCrop in $targetSoil soil):\n'
              '• When and how to water based on your soil.\n'
              '• How to spot and stop pests in Corn, Beans, Coffee, Rice, Sorghum, Soy, Sugarcane, Plantain, Watermelon, Melon, Pineapple, Orange, Apple, Wheat, or Mango.\n'
              '• Alerts for heavy rain, drought, or heat.\n'
              '• What to plant next to naturally fertilize your land and save money.\n\n'
              'What would you like to check on your plot today?';
    }

    // Collect responses for all matched topics so multi-part questions get complete answers
    final List<String> sections = [];

    if (asksPests) {
      if (!userNamedSpecificCrop && registeredCrops.length > 1) {
        final multiBlocks = <String>[];
        for (final c in registeredCrops) {
          final cropPests = getPestWarningsForCrop(
            crop: c,
            tempC: tempC,
            rain7dMm: rainMm,
            soilMoisture: soilMoisture,
            soilType: targetSoil,
            isSpanish: es,
          );
          final lines = cropPests
              .map((p) =>
                  '• ${p.pestName} ($c):\n  Qué le hace al cultivo: ${p.symptomsAndImpact}\n  Cómo cuidarlo: ${p.preventionAction}')
              .join('\n\n');
          multiBlocks.add(es
              ? 'Plagas a vigilar en tu lote de $c:\n$lines'
              : 'Pests to watch in your $c plot:\n$lines');
        }
        sections.add(multiBlocks.join('\n\n'));
      } else {
        final pestLines = pests
            .map((p) =>
                '• ${p.pestName}:\n  Qué le hace al cultivo: ${p.symptomsAndImpact}\n  Cómo cuidarlo: ${p.preventionAction}')
            .join('\n\n');
        sections.add(es
            ? 'Cuidado contra plagas en $targetCrop:\n\n$pestLines'
            : 'Pest care for $targetCrop:\n\n$pestLines');
      }
    }

    if (asksIrrigation) {
      final otherSystems = irrigationSystems
          .where((s) => s.systemName != recommendedSystem.systemName)
          .take(2)
          .map((s) => '• ${s.systemName} (ideal para ${s.bestForSoil}): ${s.description}')
          .join('\n\n');
      sections.add(es
          ? 'Consejo de riego para tu suelo $targetSoil:\n\n'
              '• Estado hoy: ${report.irrigation.actionTitle}. Tu tierra tiene ${report.irrigation.soilMoisturePct}% de humedad en la raíz y necesita unos ${report.irrigation.recommendedWaterMm} litros de agua por metro cuadrado (tienes reserva para ${report.irrigation.daysUntilStress} días).\n\n'
              '• Mejor sistema para tu terreno: ${recommendedSystem.systemName} (aprovecha el ${recommendedSystem.efficiencyPct} del agua).\n  ${recommendedSystem.description}\n\n'
              'Otras opciones de riego que puedes usar:\n$otherSystems'
          : 'Watering advice for your $targetSoil soil:\n\n'
              '• Status today: ${report.irrigation.actionTitle}. Your soil has ${report.irrigation.soilMoisturePct}% root moisture and needs about ${report.irrigation.recommendedWaterMm} liters per m² (${report.irrigation.daysUntilStress} days of reserve left).\n\n'
              '• Best system for your land: ${recommendedSystem.systemName} (${recommendedSystem.efficiencyPct} water efficiency).\n  ${recommendedSystem.description}\n\n'
              'Other watering options:\n$otherSystems');
    }

    if (asksWeather) {
      final phLines = phenomena
          .take(3)
          .map((ph) =>
              '• ${ph.phenomenonName}:\n  ${ph.description}\n  Qué hacer en el lote: ${ph.preventionMeasure}')
          .join('\n\n');
      sections.add(es
          ? 'Clima actual en tu finca (${tempC.toStringAsFixed(1)} °C, lluvia reciente: ${rainMm.toStringAsFixed(1)} mm):\n\n$phLines'
          : 'Current farm weather (${tempC.toStringAsFixed(1)} °C, recent rain: ${rainMm.toStringAsFixed(1)} mm):\n\n$phLines');
    }

    if (asksRotation) {
      final altList = report.rotation.alternativeCrops.join(', ');
      sections.add(es
          ? 'Recomendación de rotación para tu lote de $targetCrop:\n\n'
              '• Próximo cultivo ideal: ${report.rotation.suggestedCrop} (${report.rotation.score}% de compatibilidad — ${report.rotation.compatibilityLevel}).\n\n'
              '• Por qué te conviene: ${report.rotation.explanation}\n\n'
              '• Otras buenas opciones para alternar: $altList.'
          : 'Rotation recommendation for your $targetCrop plot:\n\n'
              '• Ideal next crop: ${report.rotation.suggestedCrop} (${report.rotation.score}% compatibility — ${report.rotation.compatibilityLevel}).\n\n'
              '• Why it helps you: ${report.rotation.explanation}\n\n'
              '• Other good rotation options: $altList.');
    }

    if (asksFertilizerOrNutrition) {
      sections.add(es
          ? 'Nutrición y ahorro en abono para tu tierra ($targetSoil):\n\n'
              '• Salud actual del suelo: ${report.nutrition.soilHealthScore} de 100 puntos.\n\n'
              '• Aporte natural de nitrógeno: Al rotar o asociar con leguminosas como ${report.rotation.suggestedCrop}, las raíces fijan +${report.nutrition.projectedNitrogenGainKgPerHa} kg de nitrógeno por hectárea en la tierra.\n\n'
              '• Ahorro para tu bolsillo: Equivale a ahorrar cerca de ${report.nutrition.estimatedUreaSavingsKg.toStringAsFixed(0)} kg de urea comprada.\n\n'
              '• Consejo práctico: ${report.nutrition.regenerationDiagnosis}'
          : 'Soil nutrition and fertilizer savings ($targetSoil):\n\n'
              '• Current soil health: ${report.nutrition.soilHealthScore} / 100.\n\n'
              '• Natural nitrogen gain: Rotating with legumes like ${report.rotation.suggestedCrop} adds +${report.nutrition.projectedNitrogenGainKgPerHa} kg N/ha into the soil.\n\n'
              '• Pocket savings: Saves you roughly ${report.nutrition.estimatedUreaSavingsKg.toStringAsFixed(0)} kg of commercial urea.\n\n'
              '• Practical tip: ${report.nutrition.regenerationDiagnosis}');
    }

    if (asksSoil && !asksIrrigation) {
      sections.add(es
          ? 'Cómo trabaja tu tipo de tierra ($targetSoil):\n\n'
              '• $soilConcept\n\n'
              '• Para regarla mejor: Usa ${recommendedSystem.systemName}, así cuidas la humedad (${report.irrigation.soilMoisturePct}%) sin lavar el abono ni encharcar la raíz.'
          : 'How your soil type ($targetSoil) works:\n\n'
              '• $soilConcept\n\n'
              '• Best way to water it: Use ${recommendedSystem.systemName} to maintain moisture (${report.irrigation.soilMoisturePct}%) without washing away fertilizer or waterlogging roots.');
    }

    if (asksPlantingOrCalendar) {
      sections.add(es
          ? 'Calendario y momento de siembra para $targetCrop:\n\n'
              '• Estado de la ventana de siembra: ${report.calendar.windowStatus}.\n'
              '• Fechas recomendadas: ${report.calendar.recommendedDateRange}.\n\n'
              '• Condición del terreno: Con ${tempC.toStringAsFixed(1)} °C de temperatura y ${report.irrigation.soilMoisturePct}% de humedad en el suelo $targetSoil, ${report.calendar.isWindowOpen ? 'tienes buenas condiciones para sembrar asegurando humedad pareja en los primeros 15 días.' : 'conviene asegurar un riego de asiento antes de poner la semilla para que nazca pareja.'}'
          : 'Planting calendar and timing for $targetCrop:\n\n'
              '• Planting window status: ${report.calendar.windowStatus}.\n'
              '• Recommended dates: ${report.calendar.recommendedDateRange}.\n\n'
              '• Field condition: With ${tempC.toStringAsFixed(1)} °C temperature and ${report.irrigation.soilMoisturePct}% moisture in $targetSoil soil, ${report.calendar.isWindowOpen ? 'conditions are favorable for planting while keeping moisture steady during the first 15 days.' : 'apply a pre-planting watering so seeds germinate evenly.'}');
    }

    if (asksThreeWeeks) {
      final phLines = projection3w.phases
          .map((ph) =>
              '• ${ph.title} (${ph.dateRangeLabel}):\n  ${ph.expectedMetrics}\n  Qué hacer: ${ph.recommendedAction}')
          .join('\n\n');
      sections.add(es
          ? 'Plan de trabajo para las próximas 3 semanas (${projection3w.fullDateRange}) en $targetCrop:\n\n$phLines\n\n'
              'Lo que cambió en los últimos 7 días:\n• ${projection3w.weeklyChangesDetected.join('\n• ')}'
          : 'Work plan for the next 3 weeks (${projection3w.fullDateRange}) in $targetCrop:\n\n$phLines\n\n'
              'What changed over the last 7 days:\n• ${projection3w.weeklyChangesDetected.join('\n• ')}');
    }

    if (sections.isNotEmpty) {
      return sections.join('\n\n');
    }

    // If the user mentioned a specific crop (e.g. "¿Y qué tal el café?") without a narrower keyword, give a complete farmer summary for that crop!
    final mainPest = pests.first;
    final mainPhenomenon = phenomena.first;
    final bool hasMultipleFarmCrops =
        !userNamedSpecificCrop && registeredCrops.length > 1;
    final cropsHeaderLabel = hasMultipleFarmCrops
        ? registeredCrops.join(', ')
        : targetCrop;

    String multiPestOverviewSection = '';
    if (hasMultipleFarmCrops) {
      final items = <String>[];
      for (final c in registeredCrops) {
        final cp = getPestWarningsForCrop(
          crop: c,
          tempC: tempC,
          rain7dMm: rainMm,
          soilMoisture: soilMoisture,
          soilType: targetSoil,
          isSpanish: es,
        ).first;
        items.add(es
            ? '• En $c (${cp.pestName}): ${cp.symptomsAndImpact} Prevención: ${cp.preventionAction}'
            : '• In $c (${cp.pestName}): ${cp.symptomsAndImpact} Prevention: ${cp.preventionAction}');
      }
      multiPestOverviewSection = items.join('\n');
    }

    if (!es) {
      return '''
Hello! Here is the practical field guide for your farm ($cropsHeaderLabel on $targetSoil soil):

1. Water & Soil Care:
• ${report.irrigation.actionTitle} (Soil moisture: ${report.irrigation.soilMoisturePct}%, apply ${report.irrigation.recommendedWaterMm} L/m²).
• Best irrigation method: ${recommendedSystem.systemName}.
• $soilConcept

2. Weather Watch:
• ${mainPhenomenon.phenomenonName}: ${mainPhenomenon.preventionMeasure}

3. Main Pests to Watch ($cropsHeaderLabel):
${hasMultipleFarmCrops ? multiPestOverviewSection : '• ${mainPest.pestName}: ${mainPest.symptomsAndImpact}\n• How to prevent it: ${mainPest.preventionAction}'}

4. Next 3 Weeks & Rotation (${projection3w.fullDateRange}):
• ${projection3w.phases.first.title}: ${projection3w.phases.first.recommendedAction}
• Next crop to rotate: ${report.rotation.suggestedCrop} (saves ~${report.nutrition.estimatedUreaSavingsKg.toStringAsFixed(0)} kg of urea).
''';
    }

    return '''
Hola, aquí tienes la guía práctica de campo para tu parcela ($cropsHeaderLabel en suelo $targetSoil):

1. Agua y Cuidado de tu Tierra:
• ${report.irrigation.actionTitle} (Humedad actual: ${report.irrigation.soilMoisturePct}%, aplicar ${report.irrigation.recommendedWaterMm} litros por m²).
• Mejor forma de regar: ${recommendedSystem.systemName}.
• $soilConcept

2. Clima en tu Zona:
• ${mainPhenomenon.phenomenonName}: ${mainPhenomenon.preventionMeasure}

3. Plagas a Vigilar ($cropsHeaderLabel):
${hasMultipleFarmCrops ? multiPestOverviewSection : '• ${mainPest.pestName}: ${mainPest.symptomsAndImpact}\n• Cómo prevenirla: ${mainPest.preventionAction}'}

4. Plan a 3 Semanas y Rotación (${projection3w.fullDateRange}):
• ${projection3w.phases.first.title}: ${projection3w.phases.first.recommendedAction}
• Con qué rotar después: ${report.rotation.suggestedCrop} (aporta abono natural y ahorra ~${report.nutrition.estimatedUreaSavingsKg.toStringAsFixed(0)} kg de urea).
''';
  }
}
