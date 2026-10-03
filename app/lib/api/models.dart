// Typed views of the backend's JSON. Field names follow the API exactly.

typedef Json = Map<String, dynamic>;

double? _toDouble(Object? value) => value is num ? value.toDouble() : null;
List<T> _list<T>(Object? value, T Function(Json) parse) =>
    value is List ? value.whereType<Json>().map(parse).toList() : <T>[];
List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

enum EventTemplate { prom, theatre, group }

enum Pose { standing, seated }

enum ItemType { garment, makeup, hair }

enum GarmentCategory {
  fullBody('full_body'),
  upperBody('upper_body'),
  lowerBody('lower_body'),
  outer('outer');

  const GarmentCategory(this.apiName);

  /// The name the API uses.
  final String apiName;

  static GarmentCategory fromApi(String value) =>
      values.firstWhere((c) => c.apiName == value);
}

class AppConfigInfo {
  const AppConfigInfo({
    required this.authMode,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.youcamMode,
    required this.dataMode,
    required this.explainAvailable,
  });

  factory AppConfigInfo.fromJson(Json json) => AppConfigInfo(
    authMode: json['authMode'] as String? ?? 'dev',
    supabaseUrl: json['supabaseUrl'] as String?,
    supabasePublishableKey: json['supabasePublishableKey'] as String?,
    youcamMode: json['youcamMode'] as String? ?? 'mock',
    dataMode: json['dataMode'] as String? ?? 'memory',
    explainAvailable: json['explainAvailable'] == true,
  );

  final String authMode;
  final String? supabaseUrl;
  final String? supabasePublishableKey;
  final String youcamMode;
  final String dataMode;
  final bool explainAvailable;

  bool get isMock => youcamMode == 'mock';
}

class EventInfo {
  const EventInfo({
    required this.id,
    required this.name,
    required this.template,
    required this.joinCode,
    required this.budgetPerPerson,
    required this.budgetTotal,
    required this.currency,
    required this.demo,
    required this.isOrganizer,
    required this.isParticipant,
    this.eventDate,
    this.me,
  });

  factory EventInfo.fromJson(Json json) => EventInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    template: EventTemplate.values.byName(json['template'] as String),
    joinCode: json['joinCode'] as String? ?? '',
    budgetPerPerson: _toDouble(json['budgetPerPerson']),
    budgetTotal: _toDouble(json['budgetTotal']),
    currency: json['currency'] as String? ?? 'EUR',
    demo: json['demo'] == true,
    isOrganizer: json['isOrganizer'] == true,
    isParticipant: json['isParticipant'] == true,
    eventDate: parseDay(json['eventDate']),
    me: json['me'] is Json ? Participant.fromJson(json['me'] as Json) : null,
  );

  final String id;
  final String name;
  final EventTemplate template;
  final String joinCode;
  final double? budgetPerPerson;
  final double? budgetTotal;
  final String currency;
  final bool demo;
  final bool isOrganizer;
  final bool isParticipant;

  /// The day of the event (local midnight), if the organizer set one.
  final DateTime? eventDate;
  final Participant? me;
}

/// Parses a YYYY-MM-DD day as a local date, or null.
DateTime? parseDay(Object? value) {
  if (value is! String) return null;
  final parts = value.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((p) => p == null)) return null;
  return DateTime(parts[0]!, parts[1]!, parts[2]!);
}

/// Formats a day as YYYY-MM-DD for the API.
String formatDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

class PhotoQuality {
  const PhotoQuality({required this.issues, required this.warnings});

  factory PhotoQuality.fromJson(Json json) => PhotoQuality(
    issues: _strings(json['issues']),
    warnings: _strings(json['warnings']),
  );

  final List<String> issues;
  final List<String> warnings;
}

class Participant {
  const Participant({
    required this.userId,
    required this.displayName,
    required this.pairWith,
    required this.pose,
    required this.consentAt,
    required this.hasPhoto,
    required this.photoUrl,
    required this.photoQuality,
  });

  factory Participant.fromJson(Json json) => Participant(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    pairWith: json['pairWith'] as String?,
    pose: json['pose'] == null
        ? null
        : Pose.values.byName(json['pose'] as String),
    consentAt: json['consentAt'] as String?,
    hasPhoto: json['hasPhoto'] == true,
    photoUrl: json['photoUrl'] as String?,
    photoQuality: json['photoQuality'] is Json
        ? PhotoQuality.fromJson(json['photoQuality'] as Json)
        : null,
  );

  final String userId;
  final String displayName;
  final String? pairWith;
  final Pose? pose;
  final String? consentAt;
  final bool hasPhoto;
  final String? photoUrl;
  final PhotoQuality? photoQuality;

  bool get hasConsent => consentAt != null;
}

class ColorShare {
  const ColorShare({required this.hex, required this.share});

  factory ColorShare.fromJson(Json json) => ColorShare(
    hex: json['hex'] as String,
    share: _toDouble(json['share']) ?? 0,
  );

  final String hex;
  final double share;
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    required this.category,
    required this.colorHex,
    required this.colors,
    required this.imageUrl,
    required this.vendorName,
    required this.hasImage,
  });

  factory CatalogItem.fromJson(Json json) => CatalogItem(
    id: json['id'] as String,
    type: ItemType.values.byName(json['type'] as String),
    name: json['name'] as String,
    price: _toDouble(json['price']) ?? 0,
    category: json['category'] == null
        ? null
        : GarmentCategory.fromApi(json['category'] as String),
    colorHex: json['colorHex'] as String?,
    colors: _list(json['colors'], ColorShare.fromJson),
    imageUrl: json['imageUrl'] as String?,
    vendorName: json['vendorName'] as String?,
    hasImage: json['hasImage'] == true,
  );

  final String id;
  final ItemType type;
  final String name;
  final double price;
  final GarmentCategory? category;
  final String? colorHex;
  final List<ColorShare> colors;
  final String? imageUrl;
  final String? vendorName;
  final bool hasImage;
}

class RenderFailure {
  const RenderFailure({
    required this.reason,
    required this.message,
    required this.retryable,
  });

  factory RenderFailure.fromJson(Json json) => RenderFailure(
    reason: json['reason'] as String? ?? 'provider_error',
    message: json['message'] as String? ?? '',
    retryable: json['retryable'] == true,
  );

  final String reason;
  final String message;
  final bool retryable;
}

class RenderChecks {
  const RenderChecks({required this.garmentApplied, required this.drift});

  factory RenderChecks.fromJson(Json json) => RenderChecks(
    garmentApplied: json['garmentApplied'] != false,
    drift: json['drift'] == true,
  );

  final bool garmentApplied;
  final bool drift;
}

class RenderStep {
  const RenderStep({required this.kind, required this.status});

  factory RenderStep.fromJson(Json json) => RenderStep(
    kind: json['kind'] as String,
    status: json['status'] as String,
  );

  final String kind;
  final String status;
}

/// Where a participant's look is in the render chain (apparel, makeup, hair).
class RenderState {
  const RenderState({
    required this.status,
    required this.steps,
    required this.current,
    required this.progress,
    required this.resultUrl,
    required this.failure,
    required this.mock,
    required this.checks,
    required this.units,
  });

  factory RenderState.fromJson(Json json) => RenderState(
    status: json['status'] as String? ?? 'empty',
    steps: _list(json['steps'], RenderStep.fromJson),
    current: json['current'] as String?,
    progress: _toDouble(json['progress']) ?? 0,
    resultUrl: json['resultUrl'] as String?,
    failure: json['failure'] is Json
        ? RenderFailure.fromJson(json['failure'] as Json)
        : null,
    mock: json['mock'] == true,
    checks: json['checks'] is Json
        ? RenderChecks.fromJson(json['checks'] as Json)
        : null,
    units: _toDouble(json['units']) ?? 0,
  );

  /// no_photo, empty, idle, running, success, failed
  final String status;
  final List<RenderStep> steps;
  final String? current;
  final double progress;
  final String? resultUrl;
  final RenderFailure? failure;
  final bool mock;
  final RenderChecks? checks;
  final double units;

  bool get isRunning => status == 'running';
}

class Look {
  const Look({
    required this.garmentId,
    required this.makeupId,
    required this.hairId,
    required this.locked,
    required this.total,
    required this.currency,
    required this.render,
  });

  factory Look.fromJson(Json json) => Look(
    garmentId: json['garmentId'] as String?,
    makeupId: json['makeupId'] as String?,
    hairId: json['hairId'] as String?,
    locked: json['locked'] == true,
    total: _toDouble(json['total']) ?? 0,
    currency: json['currency'] as String? ?? 'EUR',
    render: RenderState.fromJson((json['render'] as Json?) ?? const {}),
  );

  final String? garmentId;
  final String? makeupId;
  final String? hairId;
  final bool locked;
  final double total;
  final String currency;
  final RenderState render;

  bool get isEmpty => garmentId == null && makeupId == null && hairId == null;
}

class ItemSummary {
  const ItemSummary({
    required this.id,
    required this.name,
    required this.price,
    required this.colorHex,
  });

  factory ItemSummary.fromJson(Json json) => ItemSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    price: _toDouble(json['price']) ?? 0,
    colorHex: json['colorHex'] as String?,
  );

  final String id;
  final String name;
  final double price;
  final String? colorHex;
}

class BoardLook {
  const BoardLook({
    required this.garment,
    required this.makeup,
    required this.hair,
    required this.locked,
    required this.total,
  });

  factory BoardLook.fromJson(Json json) {
    ItemSummary? item(String key) =>
        json[key] is Json ? ItemSummary.fromJson(json[key] as Json) : null;
    return BoardLook(
      garment: item('garment'),
      makeup: item('makeup'),
      hair: item('hair'),
      locked: json['locked'] == true,
      total: _toDouble(json['total']) ?? 0,
    );
  }

  final ItemSummary? garment;
  final ItemSummary? makeup;
  final ItemSummary? hair;
  final bool locked;
  final double total;
}

class BoardParticipant {
  const BoardParticipant({
    required this.userId,
    required this.displayName,
    required this.pairWith,
    required this.pose,
    required this.isMe,
    required this.hasPhoto,
    required this.photoUrl,
    required this.look,
    required this.overBudget,
    required this.render,
  });

  factory BoardParticipant.fromJson(Json json) => BoardParticipant(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    pairWith: json['pairWith'] as String?,
    pose: json['pose'] == null
        ? null
        : Pose.values.byName(json['pose'] as String),
    isMe: json['isMe'] == true,
    hasPhoto: json['hasPhoto'] == true,
    photoUrl: json['photoUrl'] as String?,
    look: BoardLook.fromJson((json['look'] as Json?) ?? const {}),
    overBudget: json['overBudget'] == true,
    render: RenderState.fromJson((json['render'] as Json?) ?? const {}),
  );

  final String userId;
  final String displayName;
  final String? pairWith;
  final Pose? pose;
  final bool isMe;
  final bool hasPhoto;
  final String? photoUrl;
  final BoardLook look;
  final bool overBudget;
  final RenderState render;

  /// The best picture of this person: the render if there is one, else the photo.
  String? get pictureUrl => render.resultUrl ?? photoUrl;
}

class BudgetInfo {
  const BudgetInfo({
    required this.currency,
    required this.perPersonCap,
    required this.totalCap,
    required this.total,
    required this.overTotal,
    required this.overBudgetCount,
  });

  factory BudgetInfo.fromJson(Json json) => BudgetInfo(
    currency: json['currency'] as String? ?? 'EUR',
    perPersonCap: _toDouble(json['perPersonCap']),
    totalCap: _toDouble(json['totalCap']),
    total: _toDouble(json['total']) ?? 0,
    overTotal: json['overTotal'] == true,
    overBudgetCount: (json['overBudgetCount'] as num?)?.toInt() ?? 0,
  );

  final String currency;
  final double? perPersonCap;
  final double? totalCap;
  final double total;
  final bool overTotal;
  final int overBudgetCount;
}

class UnitsInfo {
  const UnitsInfo({required this.used, required this.cap, required this.mode});

  factory UnitsInfo.fromJson(Json json) => UnitsInfo(
    used: _toDouble(json['used']) ?? 0,
    cap: _toDouble(json['cap']) ?? 0,
    mode: json['mode'] as String? ?? 'mock',
  );

  final double used;
  final double cap;

  /// live, mock or demo
  final String mode;
}

class HarmonyColor {
  const HarmonyColor({
    required this.hex,
    required this.base,
    required this.modifier,
    required this.label,
  });

  factory HarmonyColor.fromJson(Json json) {
    final name = (json['name'] as Json?) ?? const {};
    return HarmonyColor(
      hex: json['hex'] as String,
      base: name['base'] as String? ?? 'gray',
      modifier: name['modifier'] as String?,
      label: name['label'] as String? ?? '',
    );
  }

  final String hex;
  final String base;
  final String? modifier;
  final String label;
}

class HarmonyFinding {
  const HarmonyFinding({
    required this.scope,
    required this.people,
    required this.names,
    required this.subjects,
    required this.colors,
    required this.relation,
    required this.deltaE,
    required this.score,
    required this.partners,
    required this.sentence,
  });

  factory HarmonyFinding.fromJson(Json json) => HarmonyFinding(
    scope: json['scope'] as String,
    people: _strings(json['people']),
    names: _strings(json['names']),
    subjects: _strings(json['subjects']),
    colors: _list(json['colors'], HarmonyColor.fromJson),
    relation: json['relation'] as String,
    deltaE: _toDouble(json['deltaE']) ?? 0,
    score: (json['score'] as num?)?.toInt() ?? 0,
    partners: json['partners'] == true,
    sentence: json['sentence'] as String? ?? '',
  );

  /// pair or self
  final String scope;
  final List<String> people;
  final List<String> names;

  /// outfit, lips or hair, one per color
  final List<String> subjects;
  final List<HarmonyColor> colors;

  /// matched, near_miss, complementary, contrast
  final String relation;
  final double deltaE;
  final int score;
  final bool partners;
  final String sentence;

  bool get isWarning => relation == 'near_miss';
}

class HarmonyReport {
  const HarmonyReport({
    required this.groupScore,
    required this.weakest,
    required this.findings,
    required this.withoutOutfit,
  });

  factory HarmonyReport.fromJson(Json json) => HarmonyReport(
    groupScore: (json['groupScore'] as num?)?.toInt(),
    weakest: json['weakest'] is Json
        ? HarmonyFinding.fromJson(json['weakest'] as Json)
        : null,
    findings: _list(json['findings'], HarmonyFinding.fromJson),
    withoutOutfit: _strings(json['withoutOutfit']),
  );

  final int? groupScore;
  final HarmonyFinding? weakest;
  final List<HarmonyFinding> findings;
  final List<String> withoutOutfit;

  List<HarmonyFinding> get warnings =>
      findings.where((f) => f.isWarning).toList();
}

class Board {
  const Board({
    required this.event,
    required this.participants,
    required this.participantCount,
    required this.renderedCount,
    required this.lockedCount,
    required this.budget,
    required this.units,
    required this.harmony,
  });

  factory Board.fromJson(Json json) => Board(
    event: EventInfo.fromJson(json['event'] as Json),
    participants: _list(json['participants'], BoardParticipant.fromJson),
    participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
    renderedCount: (json['renderedCount'] as num?)?.toInt() ?? 0,
    lockedCount: (json['lockedCount'] as num?)?.toInt() ?? 0,
    budget: BudgetInfo.fromJson((json['budget'] as Json?) ?? const {}),
    units: UnitsInfo.fromJson((json['units'] as Json?) ?? const {}),
    harmony: HarmonyReport.fromJson((json['harmony'] as Json?) ?? const {}),
  );

  final EventInfo event;
  final List<BoardParticipant> participants;
  final int participantCount;
  final int renderedCount;
  final int lockedCount;
  final BudgetInfo budget;
  final UnitsInfo units;
  final HarmonyReport harmony;

  BoardParticipant? get me => participants.where((p) => p.isMe).firstOrNull;

  BoardParticipant? byId(String? userId) =>
      participants.where((p) => p.userId == userId).firstOrNull;
}

/// A catalogue swap that would remove a near-miss, as computed by the harmony engine.
class FixSuggestion {
  const FixSuggestion({
    required this.userId,
    required this.name,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.colorHex,
    required this.imageUrl,
    required this.price,
    required this.priceDelta,
    required this.relationAfter,
    required this.deltaEAfter,
    required this.otherUserId,
    required this.otherName,
    required this.groupScoreBefore,
    required this.groupScoreAfter,
    required this.warningsAfter,
    required this.withinBudget,
  });

  factory FixSuggestion.fromJson(Json json) => FixSuggestion(
    userId: json['userId'] as String,
    name: json['name'] as String? ?? '',
    itemId: json['itemId'] as String,
    itemName: json['itemName'] as String? ?? '',
    itemType: ItemType.values.byName(json['itemType'] as String? ?? 'garment'),
    colorHex: json['colorHex'] as String? ?? '#999999',
    imageUrl: json['imageUrl'] as String?,
    price: _toDouble(json['price']) ?? 0,
    priceDelta: _toDouble(json['priceDelta']) ?? 0,
    relationAfter: json['relationAfter'] as String? ?? 'contrast',
    deltaEAfter: _toDouble(json['deltaEAfter']) ?? 0,
    otherUserId: json['otherUserId'] as String?,
    otherName: json['otherName'] as String?,
    groupScoreBefore: (json['groupScoreBefore'] as num?)?.toInt(),
    groupScoreAfter: (json['groupScoreAfter'] as num?)?.toInt(),
    warningsAfter: (json['warningsAfter'] as num?)?.toInt() ?? 0,
    withinBudget: json['withinBudget'] != false,
  );

  /// The person who would change.
  final String userId;
  final String name;
  final String itemId;
  final String itemName;
  final ItemType itemType;
  final String colorHex;
  final String? imageUrl;
  final double price;

  /// New item price minus the price of the item it replaces.
  final double priceDelta;
  final String relationAfter;
  final double deltaEAfter;

  /// For a pair: the other person; null when fixing someone's own colors.
  final String? otherUserId;
  final String? otherName;
  final int? groupScoreBefore;
  final int? groupScoreAfter;
  final int warningsAfter;
  final bool withinBudget;
}

class FixSuggestions {
  const FixSuggestions({required this.target, required this.suggestions});

  factory FixSuggestions.fromJson(Json json) => FixSuggestions(
    target: json['target'] is Json
        ? HarmonyFinding.fromJson(json['target'] as Json)
        : null,
    suggestions: _list(json['suggestions'], FixSuggestion.fromJson),
  );

  /// The near-miss being fixed, or null if there is none.
  final HarmonyFinding? target;
  final List<FixSuggestion> suggestions;
}

class JoinPreview {
  const JoinPreview({
    required this.name,
    required this.template,
    required this.demo,
  });

  factory JoinPreview.fromJson(Json json) => JoinPreview(
    name: json['name'] as String,
    template: EventTemplate.values.byName(json['template'] as String),
    demo: json['demo'] == true,
  );

  final String name;
  final EventTemplate template;
  final bool demo;
}

class VendorLinkCreated {
  const VendorLinkCreated({
    required this.token,
    required this.path,
    required this.expiresAt,
  });

  factory VendorLinkCreated.fromJson(Json json) => VendorLinkCreated(
    token: json['token'] as String,
    path: json['path'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  final String token;
  final String path;
  final DateTime expiresAt;
}

class VendorView {
  const VendorView({
    required this.scope,
    required this.expiresAt,
    required this.vendorName,
    required this.eventName,
    required this.currency,
    required this.demo,
    required this.participantName,
    required this.photoUrl,
    required this.resultUrl,
    required this.resultIsSimulated,
    required this.garment,
    required this.makeup,
    required this.hair,
    required this.items,
  });

  factory VendorView.fromJson(Json json) {
    final event = (json['event'] as Json?) ?? const {};
    CatalogItem? item(String key) =>
        json[key] is Json ? CatalogItem.fromJson(json[key] as Json) : null;
    return VendorView(
      scope: json['scope'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      vendorName: json['vendorName'] as String?,
      eventName: event['name'] as String? ?? '',
      currency: event['currency'] as String? ?? 'EUR',
      demo: event['demo'] == true,
      participantName:
          (json['participant'] as Json?)?['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      resultUrl: json['resultUrl'] as String?,
      resultIsSimulated: json['resultIsSimulated'] == true,
      garment: item('garment'),
      makeup: item('makeup'),
      hair: item('hair'),
      items: _list(json['items'], CatalogItem.fromJson),
    );
  }

  /// look, hair or catalogue
  final String scope;
  final DateTime expiresAt;
  final String? vendorName;
  final String eventName;
  final String currency;
  final bool demo;
  final String? participantName;
  final String? photoUrl;
  final String? resultUrl;
  final bool resultIsSimulated;
  final CatalogItem? garment;
  final CatalogItem? makeup;
  final CatalogItem? hair;
  final List<CatalogItem> items;
}

class InclusionGroup {
  const InclusionGroup({
    required this.pose,
    required this.framing,
    required this.runs,
    required this.success,
    required this.silentFailures,
    required this.errors,
    required this.identityDrift,
    required this.medianLatencySeconds,
  });

  factory InclusionGroup.fromJson(Json json) => InclusionGroup(
    pose: json['pose'] as String,
    framing: json['framing'] as String,
    runs: (json['runs'] as num?)?.toInt() ?? 0,
    success: (json['success'] as num?)?.toInt() ?? 0,
    silentFailures: (json['silentFailures'] as num?)?.toInt() ?? 0,
    errors: (json['errors'] as num?)?.toInt() ?? 0,
    identityDrift: (json['identityDrift'] as num?)?.toInt(),
    medianLatencySeconds: _toDouble(json['medianLatencySeconds']),
  );

  final String pose;
  final String framing;
  final int runs;
  final int success;
  final int silentFailures;
  final int errors;
  final int? identityDrift;
  final double? medianLatencySeconds;
}

class InclusionResults {
  const InclusionResults({
    required this.measuredAt,
    required this.engine,
    required this.groups,
    required this.notes,
  });

  factory InclusionResults.fromJson(Json json) => InclusionResults(
    measuredAt: json['measuredAt'] as String?,
    engine: json['engine'] as String? ?? '',
    groups: _list(json['groups'], InclusionGroup.fromJson),
    notes: _strings(json['notes']),
  );

  final String? measuredAt;
  final String engine;
  final List<InclusionGroup> groups;
  final List<String> notes;
}
