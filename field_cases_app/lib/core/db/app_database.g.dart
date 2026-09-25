// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LookupItemsTable extends LookupItems
    with TableInfo<$LookupItemsTable, LookupItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LookupItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listKeyMeta = const VerificationMeta(
    'listKey',
  );
  @override
  late final GeneratedColumn<String> listKey = GeneratedColumn<String>(
    'list_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listKey,
    code,
    label,
    parentId,
    sortOrder,
    isActive,
    isSystem,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lookup_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LookupItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_key')) {
      context.handle(
        _listKeyMeta,
        listKey.isAcceptableOrUnknown(data['list_key']!, _listKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_listKeyMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {listKey, code},
  ];
  @override
  LookupItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LookupItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_key'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
    );
  }

  @override
  $LookupItemsTable createAlias(String alias) {
    return $LookupItemsTable(attachedDatabase, alias);
  }
}

class LookupItem extends DataClass implements Insertable<LookupItem> {
  final String id;
  final String listKey;
  final String code;
  final String label;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final bool isSystem;
  const LookupItem({
    required this.id,
    required this.listKey,
    required this.code,
    required this.label,
    this.parentId,
    required this.sortOrder,
    required this.isActive,
    required this.isSystem,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_key'] = Variable<String>(listKey);
    map['code'] = Variable<String>(code);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['is_system'] = Variable<bool>(isSystem);
    return map;
  }

  LookupItemsCompanion toCompanion(bool nullToAbsent) {
    return LookupItemsCompanion(
      id: Value(id),
      listKey: Value(listKey),
      code: Value(code),
      label: Value(label),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      isSystem: Value(isSystem),
    );
  }

  factory LookupItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LookupItem(
      id: serializer.fromJson<String>(json['id']),
      listKey: serializer.fromJson<String>(json['listKey']),
      code: serializer.fromJson<String>(json['code']),
      label: serializer.fromJson<String>(json['label']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listKey': serializer.toJson<String>(listKey),
      'code': serializer.toJson<String>(code),
      'label': serializer.toJson<String>(label),
      'parentId': serializer.toJson<String?>(parentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'isSystem': serializer.toJson<bool>(isSystem),
    };
  }

  LookupItem copyWith({
    String? id,
    String? listKey,
    String? code,
    String? label,
    Value<String?> parentId = const Value.absent(),
    int? sortOrder,
    bool? isActive,
    bool? isSystem,
  }) => LookupItem(
    id: id ?? this.id,
    listKey: listKey ?? this.listKey,
    code: code ?? this.code,
    label: label ?? this.label,
    parentId: parentId.present ? parentId.value : this.parentId,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    isSystem: isSystem ?? this.isSystem,
  );
  LookupItem copyWithCompanion(LookupItemsCompanion data) {
    return LookupItem(
      id: data.id.present ? data.id.value : this.id,
      listKey: data.listKey.present ? data.listKey.value : this.listKey,
      code: data.code.present ? data.code.value : this.code,
      label: data.label.present ? data.label.value : this.label,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LookupItem(')
          ..write('id: $id, ')
          ..write('listKey: $listKey, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('isSystem: $isSystem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listKey,
    code,
    label,
    parentId,
    sortOrder,
    isActive,
    isSystem,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LookupItem &&
          other.id == this.id &&
          other.listKey == this.listKey &&
          other.code == this.code &&
          other.label == this.label &&
          other.parentId == this.parentId &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.isSystem == this.isSystem);
}

class LookupItemsCompanion extends UpdateCompanion<LookupItem> {
  final Value<String> id;
  final Value<String> listKey;
  final Value<String> code;
  final Value<String> label;
  final Value<String?> parentId;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<bool> isSystem;
  final Value<int> rowid;
  const LookupItemsCompanion({
    this.id = const Value.absent(),
    this.listKey = const Value.absent(),
    this.code = const Value.absent(),
    this.label = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LookupItemsCompanion.insert({
    required String id,
    required String listKey,
    required String code,
    required String label,
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listKey = Value(listKey),
       code = Value(code),
       label = Value(label);
  static Insertable<LookupItem> custom({
    Expression<String>? id,
    Expression<String>? listKey,
    Expression<String>? code,
    Expression<String>? label,
    Expression<String>? parentId,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<bool>? isSystem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listKey != null) 'list_key': listKey,
      if (code != null) 'code': code,
      if (label != null) 'label': label,
      if (parentId != null) 'parent_id': parentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (isSystem != null) 'is_system': isSystem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LookupItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? listKey,
    Value<String>? code,
    Value<String>? label,
    Value<String?>? parentId,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<bool>? isSystem,
    Value<int>? rowid,
  }) {
    return LookupItemsCompanion(
      id: id ?? this.id,
      listKey: listKey ?? this.listKey,
      code: code ?? this.code,
      label: label ?? this.label,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isSystem: isSystem ?? this.isSystem,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listKey.present) {
      map['list_key'] = Variable<String>(listKey.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LookupItemsCompanion(')
          ..write('id: $id, ')
          ..write('listKey: $listKey, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('isSystem: $isSystem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportBatchesTable extends ImportBatches
    with TableInfo<$ImportBatchesTable, ImportBatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orgNameMeta = const VerificationMeta(
    'orgName',
  );
  @override
  late final GeneratedColumn<String> orgName = GeneratedColumn<String>(
    'org_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orgCodeMeta = const VerificationMeta(
    'orgCode',
  );
  @override
  late final GeneratedColumn<String> orgCode = GeneratedColumn<String>(
    'org_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceDeviceIdMeta = const VerificationMeta(
    'sourceDeviceId',
  );
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
    'source_device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packageCreatedAtMeta = const VerificationMeta(
    'packageCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> packageCreatedAt =
      GeneratedColumn<DateTime>(
        'package_created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseCountMeta = const VerificationMeta(
    'caseCount',
  );
  @override
  late final GeneratedColumn<int> caseCount = GeneratedColumn<int>(
    'case_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageCountMeta = const VerificationMeta(
    'imageCount',
  );
  @override
  late final GeneratedColumn<int> imageCount = GeneratedColumn<int>(
    'image_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attachmentCountMeta = const VerificationMeta(
    'attachmentCount',
  );
  @override
  late final GeneratedColumn<int> attachmentCount = GeneratedColumn<int>(
    'attachment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImportBatchStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ImportBatchStatus>($ImportBatchesTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orgName,
    orgCode,
    sourceDeviceId,
    enteredBy,
    packageCreatedAt,
    importedAt,
    formatVersion,
    caseCount,
    imageCount,
    attachmentCount,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportBatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('org_name')) {
      context.handle(
        _orgNameMeta,
        orgName.isAcceptableOrUnknown(data['org_name']!, _orgNameMeta),
      );
    }
    if (data.containsKey('org_code')) {
      context.handle(
        _orgCodeMeta,
        orgCode.isAcceptableOrUnknown(data['org_code']!, _orgCodeMeta),
      );
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
        _sourceDeviceIdMeta,
        sourceDeviceId.isAcceptableOrUnknown(
          data['source_device_id']!,
          _sourceDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    }
    if (data.containsKey('package_created_at')) {
      context.handle(
        _packageCreatedAtMeta,
        packageCreatedAt.isAcceptableOrUnknown(
          data['package_created_at']!,
          _packageCreatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageCreatedAtMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formatVersionMeta);
    }
    if (data.containsKey('case_count')) {
      context.handle(
        _caseCountMeta,
        caseCount.isAcceptableOrUnknown(data['case_count']!, _caseCountMeta),
      );
    } else if (isInserting) {
      context.missing(_caseCountMeta);
    }
    if (data.containsKey('image_count')) {
      context.handle(
        _imageCountMeta,
        imageCount.isAcceptableOrUnknown(data['image_count']!, _imageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_imageCountMeta);
    }
    if (data.containsKey('attachment_count')) {
      context.handle(
        _attachmentCountMeta,
        attachmentCount.isAcceptableOrUnknown(
          data['attachment_count']!,
          _attachmentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportBatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportBatche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orgName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}org_name'],
      ),
      orgCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}org_code'],
      ),
      sourceDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device_id'],
      ),
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      ),
      packageCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}package_created_at'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
      caseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}case_count'],
      )!,
      imageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}image_count'],
      )!,
      attachmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attachment_count'],
      )!,
      status: $ImportBatchesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $ImportBatchesTable createAlias(String alias) {
    return $ImportBatchesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ImportBatchStatus, String, String>
  $converterstatus = const EnumNameConverter<ImportBatchStatus>(
    ImportBatchStatus.values,
  );
}

class ImportBatche extends DataClass implements Insertable<ImportBatche> {
  /// = package_id في manifest.json — يكشف إعادة استيراد نفس الحزمة.
  final String id;
  final String? orgName;
  final String? orgCode;
  final String? sourceDeviceId;
  final String? enteredBy;
  final DateTime packageCreatedAt;
  final DateTime importedAt;
  final int formatVersion;
  final int caseCount;
  final int imageCount;
  final int attachmentCount;
  final ImportBatchStatus status;
  const ImportBatche({
    required this.id,
    this.orgName,
    this.orgCode,
    this.sourceDeviceId,
    this.enteredBy,
    required this.packageCreatedAt,
    required this.importedAt,
    required this.formatVersion,
    required this.caseCount,
    required this.imageCount,
    required this.attachmentCount,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || orgName != null) {
      map['org_name'] = Variable<String>(orgName);
    }
    if (!nullToAbsent || orgCode != null) {
      map['org_code'] = Variable<String>(orgCode);
    }
    if (!nullToAbsent || sourceDeviceId != null) {
      map['source_device_id'] = Variable<String>(sourceDeviceId);
    }
    if (!nullToAbsent || enteredBy != null) {
      map['entered_by'] = Variable<String>(enteredBy);
    }
    map['package_created_at'] = Variable<DateTime>(packageCreatedAt);
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['format_version'] = Variable<int>(formatVersion);
    map['case_count'] = Variable<int>(caseCount);
    map['image_count'] = Variable<int>(imageCount);
    map['attachment_count'] = Variable<int>(attachmentCount);
    {
      map['status'] = Variable<String>(
        $ImportBatchesTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  ImportBatchesCompanion toCompanion(bool nullToAbsent) {
    return ImportBatchesCompanion(
      id: Value(id),
      orgName: orgName == null && nullToAbsent
          ? const Value.absent()
          : Value(orgName),
      orgCode: orgCode == null && nullToAbsent
          ? const Value.absent()
          : Value(orgCode),
      sourceDeviceId: sourceDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceDeviceId),
      enteredBy: enteredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(enteredBy),
      packageCreatedAt: Value(packageCreatedAt),
      importedAt: Value(importedAt),
      formatVersion: Value(formatVersion),
      caseCount: Value(caseCount),
      imageCount: Value(imageCount),
      attachmentCount: Value(attachmentCount),
      status: Value(status),
    );
  }

  factory ImportBatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportBatche(
      id: serializer.fromJson<String>(json['id']),
      orgName: serializer.fromJson<String?>(json['orgName']),
      orgCode: serializer.fromJson<String?>(json['orgCode']),
      sourceDeviceId: serializer.fromJson<String?>(json['sourceDeviceId']),
      enteredBy: serializer.fromJson<String?>(json['enteredBy']),
      packageCreatedAt: serializer.fromJson<DateTime>(json['packageCreatedAt']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      caseCount: serializer.fromJson<int>(json['caseCount']),
      imageCount: serializer.fromJson<int>(json['imageCount']),
      attachmentCount: serializer.fromJson<int>(json['attachmentCount']),
      status: $ImportBatchesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orgName': serializer.toJson<String?>(orgName),
      'orgCode': serializer.toJson<String?>(orgCode),
      'sourceDeviceId': serializer.toJson<String?>(sourceDeviceId),
      'enteredBy': serializer.toJson<String?>(enteredBy),
      'packageCreatedAt': serializer.toJson<DateTime>(packageCreatedAt),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'caseCount': serializer.toJson<int>(caseCount),
      'imageCount': serializer.toJson<int>(imageCount),
      'attachmentCount': serializer.toJson<int>(attachmentCount),
      'status': serializer.toJson<String>(
        $ImportBatchesTable.$converterstatus.toJson(status),
      ),
    };
  }

  ImportBatche copyWith({
    String? id,
    Value<String?> orgName = const Value.absent(),
    Value<String?> orgCode = const Value.absent(),
    Value<String?> sourceDeviceId = const Value.absent(),
    Value<String?> enteredBy = const Value.absent(),
    DateTime? packageCreatedAt,
    DateTime? importedAt,
    int? formatVersion,
    int? caseCount,
    int? imageCount,
    int? attachmentCount,
    ImportBatchStatus? status,
  }) => ImportBatche(
    id: id ?? this.id,
    orgName: orgName.present ? orgName.value : this.orgName,
    orgCode: orgCode.present ? orgCode.value : this.orgCode,
    sourceDeviceId: sourceDeviceId.present
        ? sourceDeviceId.value
        : this.sourceDeviceId,
    enteredBy: enteredBy.present ? enteredBy.value : this.enteredBy,
    packageCreatedAt: packageCreatedAt ?? this.packageCreatedAt,
    importedAt: importedAt ?? this.importedAt,
    formatVersion: formatVersion ?? this.formatVersion,
    caseCount: caseCount ?? this.caseCount,
    imageCount: imageCount ?? this.imageCount,
    attachmentCount: attachmentCount ?? this.attachmentCount,
    status: status ?? this.status,
  );
  ImportBatche copyWithCompanion(ImportBatchesCompanion data) {
    return ImportBatche(
      id: data.id.present ? data.id.value : this.id,
      orgName: data.orgName.present ? data.orgName.value : this.orgName,
      orgCode: data.orgCode.present ? data.orgCode.value : this.orgCode,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      packageCreatedAt: data.packageCreatedAt.present
          ? data.packageCreatedAt.value
          : this.packageCreatedAt,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      caseCount: data.caseCount.present ? data.caseCount.value : this.caseCount,
      imageCount: data.imageCount.present
          ? data.imageCount.value
          : this.imageCount,
      attachmentCount: data.attachmentCount.present
          ? data.attachmentCount.value
          : this.attachmentCount,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatche(')
          ..write('id: $id, ')
          ..write('orgName: $orgName, ')
          ..write('orgCode: $orgCode, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('packageCreatedAt: $packageCreatedAt, ')
          ..write('importedAt: $importedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('caseCount: $caseCount, ')
          ..write('imageCount: $imageCount, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orgName,
    orgCode,
    sourceDeviceId,
    enteredBy,
    packageCreatedAt,
    importedAt,
    formatVersion,
    caseCount,
    imageCount,
    attachmentCount,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportBatche &&
          other.id == this.id &&
          other.orgName == this.orgName &&
          other.orgCode == this.orgCode &&
          other.sourceDeviceId == this.sourceDeviceId &&
          other.enteredBy == this.enteredBy &&
          other.packageCreatedAt == this.packageCreatedAt &&
          other.importedAt == this.importedAt &&
          other.formatVersion == this.formatVersion &&
          other.caseCount == this.caseCount &&
          other.imageCount == this.imageCount &&
          other.attachmentCount == this.attachmentCount &&
          other.status == this.status);
}

class ImportBatchesCompanion extends UpdateCompanion<ImportBatche> {
  final Value<String> id;
  final Value<String?> orgName;
  final Value<String?> orgCode;
  final Value<String?> sourceDeviceId;
  final Value<String?> enteredBy;
  final Value<DateTime> packageCreatedAt;
  final Value<DateTime> importedAt;
  final Value<int> formatVersion;
  final Value<int> caseCount;
  final Value<int> imageCount;
  final Value<int> attachmentCount;
  final Value<ImportBatchStatus> status;
  final Value<int> rowid;
  const ImportBatchesCompanion({
    this.id = const Value.absent(),
    this.orgName = const Value.absent(),
    this.orgCode = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.packageCreatedAt = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.caseCount = const Value.absent(),
    this.imageCount = const Value.absent(),
    this.attachmentCount = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportBatchesCompanion.insert({
    required String id,
    this.orgName = const Value.absent(),
    this.orgCode = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    required DateTime packageCreatedAt,
    required DateTime importedAt,
    required int formatVersion,
    required int caseCount,
    required int imageCount,
    required int attachmentCount,
    required ImportBatchStatus status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packageCreatedAt = Value(packageCreatedAt),
       importedAt = Value(importedAt),
       formatVersion = Value(formatVersion),
       caseCount = Value(caseCount),
       imageCount = Value(imageCount),
       attachmentCount = Value(attachmentCount),
       status = Value(status);
  static Insertable<ImportBatche> custom({
    Expression<String>? id,
    Expression<String>? orgName,
    Expression<String>? orgCode,
    Expression<String>? sourceDeviceId,
    Expression<String>? enteredBy,
    Expression<DateTime>? packageCreatedAt,
    Expression<DateTime>? importedAt,
    Expression<int>? formatVersion,
    Expression<int>? caseCount,
    Expression<int>? imageCount,
    Expression<int>? attachmentCount,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orgName != null) 'org_name': orgName,
      if (orgCode != null) 'org_code': orgCode,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (packageCreatedAt != null) 'package_created_at': packageCreatedAt,
      if (importedAt != null) 'imported_at': importedAt,
      if (formatVersion != null) 'format_version': formatVersion,
      if (caseCount != null) 'case_count': caseCount,
      if (imageCount != null) 'image_count': imageCount,
      if (attachmentCount != null) 'attachment_count': attachmentCount,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportBatchesCompanion copyWith({
    Value<String>? id,
    Value<String?>? orgName,
    Value<String?>? orgCode,
    Value<String?>? sourceDeviceId,
    Value<String?>? enteredBy,
    Value<DateTime>? packageCreatedAt,
    Value<DateTime>? importedAt,
    Value<int>? formatVersion,
    Value<int>? caseCount,
    Value<int>? imageCount,
    Value<int>? attachmentCount,
    Value<ImportBatchStatus>? status,
    Value<int>? rowid,
  }) {
    return ImportBatchesCompanion(
      id: id ?? this.id,
      orgName: orgName ?? this.orgName,
      orgCode: orgCode ?? this.orgCode,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      enteredBy: enteredBy ?? this.enteredBy,
      packageCreatedAt: packageCreatedAt ?? this.packageCreatedAt,
      importedAt: importedAt ?? this.importedAt,
      formatVersion: formatVersion ?? this.formatVersion,
      caseCount: caseCount ?? this.caseCount,
      imageCount: imageCount ?? this.imageCount,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orgName.present) {
      map['org_name'] = Variable<String>(orgName.value);
    }
    if (orgCode.present) {
      map['org_code'] = Variable<String>(orgCode.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (packageCreatedAt.present) {
      map['package_created_at'] = Variable<DateTime>(packageCreatedAt.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (caseCount.present) {
      map['case_count'] = Variable<int>(caseCount.value);
    }
    if (imageCount.present) {
      map['image_count'] = Variable<int>(imageCount.value);
    }
    if (attachmentCount.present) {
      map['attachment_count'] = Variable<int>(attachmentCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ImportBatchesTable.$converterstatus.toSql(status.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatchesCompanion(')
          ..write('id: $id, ')
          ..write('orgName: $orgName, ')
          ..write('orgCode: $orgCode, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('packageCreatedAt: $packageCreatedAt, ')
          ..write('importedAt: $importedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('caseCount: $caseCount, ')
          ..write('imageCount: $imageCount, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CasesTable extends Cases with TableInfo<$CasesTable, CaseRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayCodeMeta = const VerificationMeta(
    'displayCode',
  );
  @override
  late final GeneratedColumn<String> displayCode = GeneratedColumn<String>(
    'display_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialNoMeta = const VerificationMeta(
    'serialNo',
  );
  @override
  late final GeneratedColumn<int> serialNo = GeneratedColumn<int>(
    'serial_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseTypeIdMeta = const VerificationMeta(
    'caseTypeId',
  );
  @override
  late final GeneratedColumn<String> caseTypeId = GeneratedColumn<String>(
    'case_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _governorateIdMeta = const VerificationMeta(
    'governorateId',
  );
  @override
  late final GeneratedColumn<String> governorateId = GeneratedColumn<String>(
    'governorate_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _centerIdMeta = const VerificationMeta(
    'centerId',
  );
  @override
  late final GeneratedColumn<String> centerId = GeneratedColumn<String>(
    'center_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _locationTextMeta = const VerificationMeta(
    'locationText',
  );
  @override
  late final GeneratedColumn<String> locationText = GeneratedColumn<String>(
    'location_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportSourceIdMeta = const VerificationMeta(
    'reportSourceId',
  );
  @override
  late final GeneratedColumn<String> reportSourceId = GeneratedColumn<String>(
    'report_source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _locationDescriptionMeta =
      const VerificationMeta('locationDescription');
  @override
  late final GeneratedColumn<String> locationDescription =
      GeneratedColumn<String>(
        'location_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caseInfoMeta = const VerificationMeta(
    'caseInfo',
  );
  @override
  late final GeneratedColumn<String> caseInfo = GeneratedColumn<String>(
    'case_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionTakenMeta = const VerificationMeta(
    'actionTaken',
  );
  @override
  late final GeneratedColumn<String> actionTaken = GeneratedColumn<String>(
    'action_taken',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasInjuriesMeta = const VerificationMeta(
    'hasInjuries',
  );
  @override
  late final GeneratedColumn<bool> hasInjuries = GeneratedColumn<bool>(
    'has_injuries',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_injuries" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _injuriesCountMeta = const VerificationMeta(
    'injuriesCount',
  );
  @override
  late final GeneratedColumn<int> injuriesCount = GeneratedColumn<int>(
    'injuries_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasDeathsMeta = const VerificationMeta(
    'hasDeaths',
  );
  @override
  late final GeneratedColumn<bool> hasDeaths = GeneratedColumn<bool>(
    'has_deaths',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_deaths" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deathsCountMeta = const VerificationMeta(
    'deathsCount',
  );
  @override
  late final GeneratedColumn<int> deathsCount = GeneratedColumn<int>(
    'deaths_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasDamageMeta = const VerificationMeta(
    'hasDamage',
  );
  @override
  late final GeneratedColumn<bool> hasDamage = GeneratedColumn<bool>(
    'has_damage',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_damage" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _damageDescriptionMeta = const VerificationMeta(
    'damageDescription',
  );
  @override
  late final GeneratedColumn<String> damageDescription =
      GeneratedColumn<String>(
        'damage_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraFieldsJsonMeta = const VerificationMeta(
    'extraFieldsJson',
  );
  @override
  late final GeneratedColumn<String> extraFieldsJson = GeneratedColumn<String>(
    'extra_fields_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _generatedTextMeta = const VerificationMeta(
    'generatedText',
  );
  @override
  late final GeneratedColumn<String> generatedText = GeneratedColumn<String>(
    'generated_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalTextMeta = const VerificationMeta(
    'finalText',
  );
  @override
  late final GeneratedColumn<String> finalText = GeneratedColumn<String>(
    'final_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTextEditedMeta = const VerificationMeta(
    'isTextEdited',
  );
  @override
  late final GeneratedColumn<bool> isTextEdited = GeneratedColumn<bool>(
    'is_text_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_text_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orgCodeMeta = const VerificationMeta(
    'orgCode',
  );
  @override
  late final GeneratedColumn<String> orgCode = GeneratedColumn<String>(
    'org_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CaseStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CaseStatus>($CasesTable.$converterstatus);
  static const VerificationMeta _lastExportedRevisionMeta =
      const VerificationMeta('lastExportedRevision');
  @override
  late final GeneratedColumn<int> lastExportedRevision = GeneratedColumn<int>(
    'last_exported_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastExportedAtMeta = const VerificationMeta(
    'lastExportedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastExportedAt =
      GeneratedColumn<DateTime>(
        'last_exported_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ReviewState?, String>
  reviewState = GeneratedColumn<String>(
    'review_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ReviewState?>($CasesTable.$converterreviewStaten);
  static const VerificationMeta _sourceBatchIdMeta = const VerificationMeta(
    'sourceBatchId',
  );
  @override
  late final GeneratedColumn<String> sourceBatchId = GeneratedColumn<String>(
    'source_batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES import_batches (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayCode,
    serialNo,
    caseTypeId,
    occurredAt,
    governorateId,
    centerId,
    locationText,
    reportSourceId,
    locationDescription,
    latitude,
    longitude,
    caseInfo,
    actionTaken,
    hasInjuries,
    injuriesCount,
    hasDeaths,
    deathsCount,
    hasDamage,
    damageDescription,
    notes,
    extraFieldsJson,
    generatedText,
    finalText,
    isTextEdited,
    enteredBy,
    orgCode,
    originDeviceId,
    revision,
    contentHash,
    status,
    lastExportedRevision,
    lastExportedAt,
    reviewState,
    sourceBatchId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cases';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaseRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_code')) {
      context.handle(
        _displayCodeMeta,
        displayCode.isAcceptableOrUnknown(
          data['display_code']!,
          _displayCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayCodeMeta);
    }
    if (data.containsKey('serial_no')) {
      context.handle(
        _serialNoMeta,
        serialNo.isAcceptableOrUnknown(data['serial_no']!, _serialNoMeta),
      );
    } else if (isInserting) {
      context.missing(_serialNoMeta);
    }
    if (data.containsKey('case_type_id')) {
      context.handle(
        _caseTypeIdMeta,
        caseTypeId.isAcceptableOrUnknown(
          data['case_type_id']!,
          _caseTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caseTypeIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('governorate_id')) {
      context.handle(
        _governorateIdMeta,
        governorateId.isAcceptableOrUnknown(
          data['governorate_id']!,
          _governorateIdMeta,
        ),
      );
    }
    if (data.containsKey('center_id')) {
      context.handle(
        _centerIdMeta,
        centerId.isAcceptableOrUnknown(data['center_id']!, _centerIdMeta),
      );
    }
    if (data.containsKey('location_text')) {
      context.handle(
        _locationTextMeta,
        locationText.isAcceptableOrUnknown(
          data['location_text']!,
          _locationTextMeta,
        ),
      );
    }
    if (data.containsKey('report_source_id')) {
      context.handle(
        _reportSourceIdMeta,
        reportSourceId.isAcceptableOrUnknown(
          data['report_source_id']!,
          _reportSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('location_description')) {
      context.handle(
        _locationDescriptionMeta,
        locationDescription.isAcceptableOrUnknown(
          data['location_description']!,
          _locationDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('case_info')) {
      context.handle(
        _caseInfoMeta,
        caseInfo.isAcceptableOrUnknown(data['case_info']!, _caseInfoMeta),
      );
    }
    if (data.containsKey('action_taken')) {
      context.handle(
        _actionTakenMeta,
        actionTaken.isAcceptableOrUnknown(
          data['action_taken']!,
          _actionTakenMeta,
        ),
      );
    }
    if (data.containsKey('has_injuries')) {
      context.handle(
        _hasInjuriesMeta,
        hasInjuries.isAcceptableOrUnknown(
          data['has_injuries']!,
          _hasInjuriesMeta,
        ),
      );
    }
    if (data.containsKey('injuries_count')) {
      context.handle(
        _injuriesCountMeta,
        injuriesCount.isAcceptableOrUnknown(
          data['injuries_count']!,
          _injuriesCountMeta,
        ),
      );
    }
    if (data.containsKey('has_deaths')) {
      context.handle(
        _hasDeathsMeta,
        hasDeaths.isAcceptableOrUnknown(data['has_deaths']!, _hasDeathsMeta),
      );
    }
    if (data.containsKey('deaths_count')) {
      context.handle(
        _deathsCountMeta,
        deathsCount.isAcceptableOrUnknown(
          data['deaths_count']!,
          _deathsCountMeta,
        ),
      );
    }
    if (data.containsKey('has_damage')) {
      context.handle(
        _hasDamageMeta,
        hasDamage.isAcceptableOrUnknown(data['has_damage']!, _hasDamageMeta),
      );
    }
    if (data.containsKey('damage_description')) {
      context.handle(
        _damageDescriptionMeta,
        damageDescription.isAcceptableOrUnknown(
          data['damage_description']!,
          _damageDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('extra_fields_json')) {
      context.handle(
        _extraFieldsJsonMeta,
        extraFieldsJson.isAcceptableOrUnknown(
          data['extra_fields_json']!,
          _extraFieldsJsonMeta,
        ),
      );
    }
    if (data.containsKey('generated_text')) {
      context.handle(
        _generatedTextMeta,
        generatedText.isAcceptableOrUnknown(
          data['generated_text']!,
          _generatedTextMeta,
        ),
      );
    }
    if (data.containsKey('final_text')) {
      context.handle(
        _finalTextMeta,
        finalText.isAcceptableOrUnknown(data['final_text']!, _finalTextMeta),
      );
    }
    if (data.containsKey('is_text_edited')) {
      context.handle(
        _isTextEditedMeta,
        isTextEdited.isAcceptableOrUnknown(
          data['is_text_edited']!,
          _isTextEditedMeta,
        ),
      );
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    }
    if (data.containsKey('org_code')) {
      context.handle(
        _orgCodeMeta,
        orgCode.isAcceptableOrUnknown(data['org_code']!, _orgCodeMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('last_exported_revision')) {
      context.handle(
        _lastExportedRevisionMeta,
        lastExportedRevision.isAcceptableOrUnknown(
          data['last_exported_revision']!,
          _lastExportedRevisionMeta,
        ),
      );
    }
    if (data.containsKey('last_exported_at')) {
      context.handle(
        _lastExportedAtMeta,
        lastExportedAt.isAcceptableOrUnknown(
          data['last_exported_at']!,
          _lastExportedAtMeta,
        ),
      );
    }
    if (data.containsKey('source_batch_id')) {
      context.handle(
        _sourceBatchIdMeta,
        sourceBatchId.isAcceptableOrUnknown(
          data['source_batch_id']!,
          _sourceBatchIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaseRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaseRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_code'],
      )!,
      serialNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}serial_no'],
      )!,
      caseTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_type_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      governorateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}governorate_id'],
      ),
      centerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}center_id'],
      ),
      locationText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_text'],
      ),
      reportSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_source_id'],
      ),
      locationDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_description'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      caseInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_info'],
      ),
      actionTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_taken'],
      ),
      hasInjuries: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_injuries'],
      )!,
      injuriesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}injuries_count'],
      )!,
      hasDeaths: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_deaths'],
      )!,
      deathsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deaths_count'],
      )!,
      hasDamage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_damage'],
      )!,
      damageDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}damage_description'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      extraFieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_fields_json'],
      )!,
      generatedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generated_text'],
      ),
      finalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_text'],
      ),
      isTextEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_text_edited'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      ),
      orgCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}org_code'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      status: $CasesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      lastExportedRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_exported_revision'],
      ),
      lastExportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_exported_at'],
      ),
      reviewState: $CasesTable.$converterreviewStaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}review_state'],
        ),
      ),
      sourceBatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_batch_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CasesTable createAlias(String alias) {
    return $CasesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CaseStatus, String, String> $converterstatus =
      const EnumNameConverter<CaseStatus>(CaseStatus.values);
  static JsonTypeConverter2<ReviewState, String, String> $converterreviewState =
      const EnumNameConverter<ReviewState>(ReviewState.values);
  static JsonTypeConverter2<ReviewState?, String?, String?>
  $converterreviewStaten = JsonTypeConverter2.asNullable($converterreviewState);
}

class CaseRecord extends DataClass implements Insertable<CaseRecord> {
  final String id;
  final String displayCode;
  final int serialNo;
  final String caseTypeId;
  final DateTime occurredAt;
  final String? governorateId;
  final String? centerId;
  final String? locationText;
  final String? reportSourceId;
  final String? locationDescription;
  final double? latitude;
  final double? longitude;
  final String? caseInfo;
  final String? actionTaken;
  final bool hasInjuries;
  final int injuriesCount;
  final bool hasDeaths;
  final int deathsCount;
  final bool hasDamage;
  final String? damageDescription;
  final String? notes;

  /// قيم الحقول الخاصة بنوع الحالة (JSON) — إضافة حقل لا تحتاج Migration.
  final String extraFieldsJson;
  final String? generatedText;
  final String? finalText;
  final bool isTextEdited;
  final String? enteredBy;
  final String? orgCode;
  final String originDeviceId;

  /// يزيد بمقدار 1 مع كل تعديل محفوظ.
  final int revision;
  final String? contentHash;
  final CaseStatus status;
  final int? lastExportedRevision;
  final DateTime? lastExportedAt;
  final ReviewState? reviewState;
  final String? sourceBatchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const CaseRecord({
    required this.id,
    required this.displayCode,
    required this.serialNo,
    required this.caseTypeId,
    required this.occurredAt,
    this.governorateId,
    this.centerId,
    this.locationText,
    this.reportSourceId,
    this.locationDescription,
    this.latitude,
    this.longitude,
    this.caseInfo,
    this.actionTaken,
    required this.hasInjuries,
    required this.injuriesCount,
    required this.hasDeaths,
    required this.deathsCount,
    required this.hasDamage,
    this.damageDescription,
    this.notes,
    required this.extraFieldsJson,
    this.generatedText,
    this.finalText,
    required this.isTextEdited,
    this.enteredBy,
    this.orgCode,
    required this.originDeviceId,
    required this.revision,
    this.contentHash,
    required this.status,
    this.lastExportedRevision,
    this.lastExportedAt,
    this.reviewState,
    this.sourceBatchId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_code'] = Variable<String>(displayCode);
    map['serial_no'] = Variable<int>(serialNo);
    map['case_type_id'] = Variable<String>(caseTypeId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || governorateId != null) {
      map['governorate_id'] = Variable<String>(governorateId);
    }
    if (!nullToAbsent || centerId != null) {
      map['center_id'] = Variable<String>(centerId);
    }
    if (!nullToAbsent || locationText != null) {
      map['location_text'] = Variable<String>(locationText);
    }
    if (!nullToAbsent || reportSourceId != null) {
      map['report_source_id'] = Variable<String>(reportSourceId);
    }
    if (!nullToAbsent || locationDescription != null) {
      map['location_description'] = Variable<String>(locationDescription);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || caseInfo != null) {
      map['case_info'] = Variable<String>(caseInfo);
    }
    if (!nullToAbsent || actionTaken != null) {
      map['action_taken'] = Variable<String>(actionTaken);
    }
    map['has_injuries'] = Variable<bool>(hasInjuries);
    map['injuries_count'] = Variable<int>(injuriesCount);
    map['has_deaths'] = Variable<bool>(hasDeaths);
    map['deaths_count'] = Variable<int>(deathsCount);
    map['has_damage'] = Variable<bool>(hasDamage);
    if (!nullToAbsent || damageDescription != null) {
      map['damage_description'] = Variable<String>(damageDescription);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['extra_fields_json'] = Variable<String>(extraFieldsJson);
    if (!nullToAbsent || generatedText != null) {
      map['generated_text'] = Variable<String>(generatedText);
    }
    if (!nullToAbsent || finalText != null) {
      map['final_text'] = Variable<String>(finalText);
    }
    map['is_text_edited'] = Variable<bool>(isTextEdited);
    if (!nullToAbsent || enteredBy != null) {
      map['entered_by'] = Variable<String>(enteredBy);
    }
    if (!nullToAbsent || orgCode != null) {
      map['org_code'] = Variable<String>(orgCode);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    {
      map['status'] = Variable<String>(
        $CasesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || lastExportedRevision != null) {
      map['last_exported_revision'] = Variable<int>(lastExportedRevision);
    }
    if (!nullToAbsent || lastExportedAt != null) {
      map['last_exported_at'] = Variable<DateTime>(lastExportedAt);
    }
    if (!nullToAbsent || reviewState != null) {
      map['review_state'] = Variable<String>(
        $CasesTable.$converterreviewStaten.toSql(reviewState),
      );
    }
    if (!nullToAbsent || sourceBatchId != null) {
      map['source_batch_id'] = Variable<String>(sourceBatchId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CasesCompanion toCompanion(bool nullToAbsent) {
    return CasesCompanion(
      id: Value(id),
      displayCode: Value(displayCode),
      serialNo: Value(serialNo),
      caseTypeId: Value(caseTypeId),
      occurredAt: Value(occurredAt),
      governorateId: governorateId == null && nullToAbsent
          ? const Value.absent()
          : Value(governorateId),
      centerId: centerId == null && nullToAbsent
          ? const Value.absent()
          : Value(centerId),
      locationText: locationText == null && nullToAbsent
          ? const Value.absent()
          : Value(locationText),
      reportSourceId: reportSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(reportSourceId),
      locationDescription: locationDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(locationDescription),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      caseInfo: caseInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(caseInfo),
      actionTaken: actionTaken == null && nullToAbsent
          ? const Value.absent()
          : Value(actionTaken),
      hasInjuries: Value(hasInjuries),
      injuriesCount: Value(injuriesCount),
      hasDeaths: Value(hasDeaths),
      deathsCount: Value(deathsCount),
      hasDamage: Value(hasDamage),
      damageDescription: damageDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(damageDescription),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      extraFieldsJson: Value(extraFieldsJson),
      generatedText: generatedText == null && nullToAbsent
          ? const Value.absent()
          : Value(generatedText),
      finalText: finalText == null && nullToAbsent
          ? const Value.absent()
          : Value(finalText),
      isTextEdited: Value(isTextEdited),
      enteredBy: enteredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(enteredBy),
      orgCode: orgCode == null && nullToAbsent
          ? const Value.absent()
          : Value(orgCode),
      originDeviceId: Value(originDeviceId),
      revision: Value(revision),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      status: Value(status),
      lastExportedRevision: lastExportedRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExportedRevision),
      lastExportedAt: lastExportedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExportedAt),
      reviewState: reviewState == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewState),
      sourceBatchId: sourceBatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceBatchId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CaseRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaseRecord(
      id: serializer.fromJson<String>(json['id']),
      displayCode: serializer.fromJson<String>(json['displayCode']),
      serialNo: serializer.fromJson<int>(json['serialNo']),
      caseTypeId: serializer.fromJson<String>(json['caseTypeId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      governorateId: serializer.fromJson<String?>(json['governorateId']),
      centerId: serializer.fromJson<String?>(json['centerId']),
      locationText: serializer.fromJson<String?>(json['locationText']),
      reportSourceId: serializer.fromJson<String?>(json['reportSourceId']),
      locationDescription: serializer.fromJson<String?>(
        json['locationDescription'],
      ),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      caseInfo: serializer.fromJson<String?>(json['caseInfo']),
      actionTaken: serializer.fromJson<String?>(json['actionTaken']),
      hasInjuries: serializer.fromJson<bool>(json['hasInjuries']),
      injuriesCount: serializer.fromJson<int>(json['injuriesCount']),
      hasDeaths: serializer.fromJson<bool>(json['hasDeaths']),
      deathsCount: serializer.fromJson<int>(json['deathsCount']),
      hasDamage: serializer.fromJson<bool>(json['hasDamage']),
      damageDescription: serializer.fromJson<String?>(
        json['damageDescription'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      extraFieldsJson: serializer.fromJson<String>(json['extraFieldsJson']),
      generatedText: serializer.fromJson<String?>(json['generatedText']),
      finalText: serializer.fromJson<String?>(json['finalText']),
      isTextEdited: serializer.fromJson<bool>(json['isTextEdited']),
      enteredBy: serializer.fromJson<String?>(json['enteredBy']),
      orgCode: serializer.fromJson<String?>(json['orgCode']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      revision: serializer.fromJson<int>(json['revision']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      status: $CasesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      lastExportedRevision: serializer.fromJson<int?>(
        json['lastExportedRevision'],
      ),
      lastExportedAt: serializer.fromJson<DateTime?>(json['lastExportedAt']),
      reviewState: $CasesTable.$converterreviewStaten.fromJson(
        serializer.fromJson<String?>(json['reviewState']),
      ),
      sourceBatchId: serializer.fromJson<String?>(json['sourceBatchId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayCode': serializer.toJson<String>(displayCode),
      'serialNo': serializer.toJson<int>(serialNo),
      'caseTypeId': serializer.toJson<String>(caseTypeId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'governorateId': serializer.toJson<String?>(governorateId),
      'centerId': serializer.toJson<String?>(centerId),
      'locationText': serializer.toJson<String?>(locationText),
      'reportSourceId': serializer.toJson<String?>(reportSourceId),
      'locationDescription': serializer.toJson<String?>(locationDescription),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'caseInfo': serializer.toJson<String?>(caseInfo),
      'actionTaken': serializer.toJson<String?>(actionTaken),
      'hasInjuries': serializer.toJson<bool>(hasInjuries),
      'injuriesCount': serializer.toJson<int>(injuriesCount),
      'hasDeaths': serializer.toJson<bool>(hasDeaths),
      'deathsCount': serializer.toJson<int>(deathsCount),
      'hasDamage': serializer.toJson<bool>(hasDamage),
      'damageDescription': serializer.toJson<String?>(damageDescription),
      'notes': serializer.toJson<String?>(notes),
      'extraFieldsJson': serializer.toJson<String>(extraFieldsJson),
      'generatedText': serializer.toJson<String?>(generatedText),
      'finalText': serializer.toJson<String?>(finalText),
      'isTextEdited': serializer.toJson<bool>(isTextEdited),
      'enteredBy': serializer.toJson<String?>(enteredBy),
      'orgCode': serializer.toJson<String?>(orgCode),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'revision': serializer.toJson<int>(revision),
      'contentHash': serializer.toJson<String?>(contentHash),
      'status': serializer.toJson<String>(
        $CasesTable.$converterstatus.toJson(status),
      ),
      'lastExportedRevision': serializer.toJson<int?>(lastExportedRevision),
      'lastExportedAt': serializer.toJson<DateTime?>(lastExportedAt),
      'reviewState': serializer.toJson<String?>(
        $CasesTable.$converterreviewStaten.toJson(reviewState),
      ),
      'sourceBatchId': serializer.toJson<String?>(sourceBatchId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CaseRecord copyWith({
    String? id,
    String? displayCode,
    int? serialNo,
    String? caseTypeId,
    DateTime? occurredAt,
    Value<String?> governorateId = const Value.absent(),
    Value<String?> centerId = const Value.absent(),
    Value<String?> locationText = const Value.absent(),
    Value<String?> reportSourceId = const Value.absent(),
    Value<String?> locationDescription = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> caseInfo = const Value.absent(),
    Value<String?> actionTaken = const Value.absent(),
    bool? hasInjuries,
    int? injuriesCount,
    bool? hasDeaths,
    int? deathsCount,
    bool? hasDamage,
    Value<String?> damageDescription = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? extraFieldsJson,
    Value<String?> generatedText = const Value.absent(),
    Value<String?> finalText = const Value.absent(),
    bool? isTextEdited,
    Value<String?> enteredBy = const Value.absent(),
    Value<String?> orgCode = const Value.absent(),
    String? originDeviceId,
    int? revision,
    Value<String?> contentHash = const Value.absent(),
    CaseStatus? status,
    Value<int?> lastExportedRevision = const Value.absent(),
    Value<DateTime?> lastExportedAt = const Value.absent(),
    Value<ReviewState?> reviewState = const Value.absent(),
    Value<String?> sourceBatchId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CaseRecord(
    id: id ?? this.id,
    displayCode: displayCode ?? this.displayCode,
    serialNo: serialNo ?? this.serialNo,
    caseTypeId: caseTypeId ?? this.caseTypeId,
    occurredAt: occurredAt ?? this.occurredAt,
    governorateId: governorateId.present
        ? governorateId.value
        : this.governorateId,
    centerId: centerId.present ? centerId.value : this.centerId,
    locationText: locationText.present ? locationText.value : this.locationText,
    reportSourceId: reportSourceId.present
        ? reportSourceId.value
        : this.reportSourceId,
    locationDescription: locationDescription.present
        ? locationDescription.value
        : this.locationDescription,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    caseInfo: caseInfo.present ? caseInfo.value : this.caseInfo,
    actionTaken: actionTaken.present ? actionTaken.value : this.actionTaken,
    hasInjuries: hasInjuries ?? this.hasInjuries,
    injuriesCount: injuriesCount ?? this.injuriesCount,
    hasDeaths: hasDeaths ?? this.hasDeaths,
    deathsCount: deathsCount ?? this.deathsCount,
    hasDamage: hasDamage ?? this.hasDamage,
    damageDescription: damageDescription.present
        ? damageDescription.value
        : this.damageDescription,
    notes: notes.present ? notes.value : this.notes,
    extraFieldsJson: extraFieldsJson ?? this.extraFieldsJson,
    generatedText: generatedText.present
        ? generatedText.value
        : this.generatedText,
    finalText: finalText.present ? finalText.value : this.finalText,
    isTextEdited: isTextEdited ?? this.isTextEdited,
    enteredBy: enteredBy.present ? enteredBy.value : this.enteredBy,
    orgCode: orgCode.present ? orgCode.value : this.orgCode,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    revision: revision ?? this.revision,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    status: status ?? this.status,
    lastExportedRevision: lastExportedRevision.present
        ? lastExportedRevision.value
        : this.lastExportedRevision,
    lastExportedAt: lastExportedAt.present
        ? lastExportedAt.value
        : this.lastExportedAt,
    reviewState: reviewState.present ? reviewState.value : this.reviewState,
    sourceBatchId: sourceBatchId.present
        ? sourceBatchId.value
        : this.sourceBatchId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CaseRecord copyWithCompanion(CasesCompanion data) {
    return CaseRecord(
      id: data.id.present ? data.id.value : this.id,
      displayCode: data.displayCode.present
          ? data.displayCode.value
          : this.displayCode,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
      caseTypeId: data.caseTypeId.present
          ? data.caseTypeId.value
          : this.caseTypeId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      governorateId: data.governorateId.present
          ? data.governorateId.value
          : this.governorateId,
      centerId: data.centerId.present ? data.centerId.value : this.centerId,
      locationText: data.locationText.present
          ? data.locationText.value
          : this.locationText,
      reportSourceId: data.reportSourceId.present
          ? data.reportSourceId.value
          : this.reportSourceId,
      locationDescription: data.locationDescription.present
          ? data.locationDescription.value
          : this.locationDescription,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      caseInfo: data.caseInfo.present ? data.caseInfo.value : this.caseInfo,
      actionTaken: data.actionTaken.present
          ? data.actionTaken.value
          : this.actionTaken,
      hasInjuries: data.hasInjuries.present
          ? data.hasInjuries.value
          : this.hasInjuries,
      injuriesCount: data.injuriesCount.present
          ? data.injuriesCount.value
          : this.injuriesCount,
      hasDeaths: data.hasDeaths.present ? data.hasDeaths.value : this.hasDeaths,
      deathsCount: data.deathsCount.present
          ? data.deathsCount.value
          : this.deathsCount,
      hasDamage: data.hasDamage.present ? data.hasDamage.value : this.hasDamage,
      damageDescription: data.damageDescription.present
          ? data.damageDescription.value
          : this.damageDescription,
      notes: data.notes.present ? data.notes.value : this.notes,
      extraFieldsJson: data.extraFieldsJson.present
          ? data.extraFieldsJson.value
          : this.extraFieldsJson,
      generatedText: data.generatedText.present
          ? data.generatedText.value
          : this.generatedText,
      finalText: data.finalText.present ? data.finalText.value : this.finalText,
      isTextEdited: data.isTextEdited.present
          ? data.isTextEdited.value
          : this.isTextEdited,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      orgCode: data.orgCode.present ? data.orgCode.value : this.orgCode,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      revision: data.revision.present ? data.revision.value : this.revision,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      status: data.status.present ? data.status.value : this.status,
      lastExportedRevision: data.lastExportedRevision.present
          ? data.lastExportedRevision.value
          : this.lastExportedRevision,
      lastExportedAt: data.lastExportedAt.present
          ? data.lastExportedAt.value
          : this.lastExportedAt,
      reviewState: data.reviewState.present
          ? data.reviewState.value
          : this.reviewState,
      sourceBatchId: data.sourceBatchId.present
          ? data.sourceBatchId.value
          : this.sourceBatchId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaseRecord(')
          ..write('id: $id, ')
          ..write('displayCode: $displayCode, ')
          ..write('serialNo: $serialNo, ')
          ..write('caseTypeId: $caseTypeId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('governorateId: $governorateId, ')
          ..write('centerId: $centerId, ')
          ..write('locationText: $locationText, ')
          ..write('reportSourceId: $reportSourceId, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('caseInfo: $caseInfo, ')
          ..write('actionTaken: $actionTaken, ')
          ..write('hasInjuries: $hasInjuries, ')
          ..write('injuriesCount: $injuriesCount, ')
          ..write('hasDeaths: $hasDeaths, ')
          ..write('deathsCount: $deathsCount, ')
          ..write('hasDamage: $hasDamage, ')
          ..write('damageDescription: $damageDescription, ')
          ..write('notes: $notes, ')
          ..write('extraFieldsJson: $extraFieldsJson, ')
          ..write('generatedText: $generatedText, ')
          ..write('finalText: $finalText, ')
          ..write('isTextEdited: $isTextEdited, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('orgCode: $orgCode, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('revision: $revision, ')
          ..write('contentHash: $contentHash, ')
          ..write('status: $status, ')
          ..write('lastExportedRevision: $lastExportedRevision, ')
          ..write('lastExportedAt: $lastExportedAt, ')
          ..write('reviewState: $reviewState, ')
          ..write('sourceBatchId: $sourceBatchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    displayCode,
    serialNo,
    caseTypeId,
    occurredAt,
    governorateId,
    centerId,
    locationText,
    reportSourceId,
    locationDescription,
    latitude,
    longitude,
    caseInfo,
    actionTaken,
    hasInjuries,
    injuriesCount,
    hasDeaths,
    deathsCount,
    hasDamage,
    damageDescription,
    notes,
    extraFieldsJson,
    generatedText,
    finalText,
    isTextEdited,
    enteredBy,
    orgCode,
    originDeviceId,
    revision,
    contentHash,
    status,
    lastExportedRevision,
    lastExportedAt,
    reviewState,
    sourceBatchId,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaseRecord &&
          other.id == this.id &&
          other.displayCode == this.displayCode &&
          other.serialNo == this.serialNo &&
          other.caseTypeId == this.caseTypeId &&
          other.occurredAt == this.occurredAt &&
          other.governorateId == this.governorateId &&
          other.centerId == this.centerId &&
          other.locationText == this.locationText &&
          other.reportSourceId == this.reportSourceId &&
          other.locationDescription == this.locationDescription &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.caseInfo == this.caseInfo &&
          other.actionTaken == this.actionTaken &&
          other.hasInjuries == this.hasInjuries &&
          other.injuriesCount == this.injuriesCount &&
          other.hasDeaths == this.hasDeaths &&
          other.deathsCount == this.deathsCount &&
          other.hasDamage == this.hasDamage &&
          other.damageDescription == this.damageDescription &&
          other.notes == this.notes &&
          other.extraFieldsJson == this.extraFieldsJson &&
          other.generatedText == this.generatedText &&
          other.finalText == this.finalText &&
          other.isTextEdited == this.isTextEdited &&
          other.enteredBy == this.enteredBy &&
          other.orgCode == this.orgCode &&
          other.originDeviceId == this.originDeviceId &&
          other.revision == this.revision &&
          other.contentHash == this.contentHash &&
          other.status == this.status &&
          other.lastExportedRevision == this.lastExportedRevision &&
          other.lastExportedAt == this.lastExportedAt &&
          other.reviewState == this.reviewState &&
          other.sourceBatchId == this.sourceBatchId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CasesCompanion extends UpdateCompanion<CaseRecord> {
  final Value<String> id;
  final Value<String> displayCode;
  final Value<int> serialNo;
  final Value<String> caseTypeId;
  final Value<DateTime> occurredAt;
  final Value<String?> governorateId;
  final Value<String?> centerId;
  final Value<String?> locationText;
  final Value<String?> reportSourceId;
  final Value<String?> locationDescription;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> caseInfo;
  final Value<String?> actionTaken;
  final Value<bool> hasInjuries;
  final Value<int> injuriesCount;
  final Value<bool> hasDeaths;
  final Value<int> deathsCount;
  final Value<bool> hasDamage;
  final Value<String?> damageDescription;
  final Value<String?> notes;
  final Value<String> extraFieldsJson;
  final Value<String?> generatedText;
  final Value<String?> finalText;
  final Value<bool> isTextEdited;
  final Value<String?> enteredBy;
  final Value<String?> orgCode;
  final Value<String> originDeviceId;
  final Value<int> revision;
  final Value<String?> contentHash;
  final Value<CaseStatus> status;
  final Value<int?> lastExportedRevision;
  final Value<DateTime?> lastExportedAt;
  final Value<ReviewState?> reviewState;
  final Value<String?> sourceBatchId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CasesCompanion({
    this.id = const Value.absent(),
    this.displayCode = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.caseTypeId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.governorateId = const Value.absent(),
    this.centerId = const Value.absent(),
    this.locationText = const Value.absent(),
    this.reportSourceId = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.caseInfo = const Value.absent(),
    this.actionTaken = const Value.absent(),
    this.hasInjuries = const Value.absent(),
    this.injuriesCount = const Value.absent(),
    this.hasDeaths = const Value.absent(),
    this.deathsCount = const Value.absent(),
    this.hasDamage = const Value.absent(),
    this.damageDescription = const Value.absent(),
    this.notes = const Value.absent(),
    this.extraFieldsJson = const Value.absent(),
    this.generatedText = const Value.absent(),
    this.finalText = const Value.absent(),
    this.isTextEdited = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.orgCode = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.revision = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.status = const Value.absent(),
    this.lastExportedRevision = const Value.absent(),
    this.lastExportedAt = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.sourceBatchId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CasesCompanion.insert({
    required String id,
    required String displayCode,
    required int serialNo,
    required String caseTypeId,
    required DateTime occurredAt,
    this.governorateId = const Value.absent(),
    this.centerId = const Value.absent(),
    this.locationText = const Value.absent(),
    this.reportSourceId = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.caseInfo = const Value.absent(),
    this.actionTaken = const Value.absent(),
    this.hasInjuries = const Value.absent(),
    this.injuriesCount = const Value.absent(),
    this.hasDeaths = const Value.absent(),
    this.deathsCount = const Value.absent(),
    this.hasDamage = const Value.absent(),
    this.damageDescription = const Value.absent(),
    this.notes = const Value.absent(),
    this.extraFieldsJson = const Value.absent(),
    this.generatedText = const Value.absent(),
    this.finalText = const Value.absent(),
    this.isTextEdited = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.orgCode = const Value.absent(),
    required String originDeviceId,
    this.revision = const Value.absent(),
    this.contentHash = const Value.absent(),
    required CaseStatus status,
    this.lastExportedRevision = const Value.absent(),
    this.lastExportedAt = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.sourceBatchId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayCode = Value(displayCode),
       serialNo = Value(serialNo),
       caseTypeId = Value(caseTypeId),
       occurredAt = Value(occurredAt),
       originDeviceId = Value(originDeviceId),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CaseRecord> custom({
    Expression<String>? id,
    Expression<String>? displayCode,
    Expression<int>? serialNo,
    Expression<String>? caseTypeId,
    Expression<DateTime>? occurredAt,
    Expression<String>? governorateId,
    Expression<String>? centerId,
    Expression<String>? locationText,
    Expression<String>? reportSourceId,
    Expression<String>? locationDescription,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? caseInfo,
    Expression<String>? actionTaken,
    Expression<bool>? hasInjuries,
    Expression<int>? injuriesCount,
    Expression<bool>? hasDeaths,
    Expression<int>? deathsCount,
    Expression<bool>? hasDamage,
    Expression<String>? damageDescription,
    Expression<String>? notes,
    Expression<String>? extraFieldsJson,
    Expression<String>? generatedText,
    Expression<String>? finalText,
    Expression<bool>? isTextEdited,
    Expression<String>? enteredBy,
    Expression<String>? orgCode,
    Expression<String>? originDeviceId,
    Expression<int>? revision,
    Expression<String>? contentHash,
    Expression<String>? status,
    Expression<int>? lastExportedRevision,
    Expression<DateTime>? lastExportedAt,
    Expression<String>? reviewState,
    Expression<String>? sourceBatchId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayCode != null) 'display_code': displayCode,
      if (serialNo != null) 'serial_no': serialNo,
      if (caseTypeId != null) 'case_type_id': caseTypeId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (governorateId != null) 'governorate_id': governorateId,
      if (centerId != null) 'center_id': centerId,
      if (locationText != null) 'location_text': locationText,
      if (reportSourceId != null) 'report_source_id': reportSourceId,
      if (locationDescription != null)
        'location_description': locationDescription,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (caseInfo != null) 'case_info': caseInfo,
      if (actionTaken != null) 'action_taken': actionTaken,
      if (hasInjuries != null) 'has_injuries': hasInjuries,
      if (injuriesCount != null) 'injuries_count': injuriesCount,
      if (hasDeaths != null) 'has_deaths': hasDeaths,
      if (deathsCount != null) 'deaths_count': deathsCount,
      if (hasDamage != null) 'has_damage': hasDamage,
      if (damageDescription != null) 'damage_description': damageDescription,
      if (notes != null) 'notes': notes,
      if (extraFieldsJson != null) 'extra_fields_json': extraFieldsJson,
      if (generatedText != null) 'generated_text': generatedText,
      if (finalText != null) 'final_text': finalText,
      if (isTextEdited != null) 'is_text_edited': isTextEdited,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (orgCode != null) 'org_code': orgCode,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (revision != null) 'revision': revision,
      if (contentHash != null) 'content_hash': contentHash,
      if (status != null) 'status': status,
      if (lastExportedRevision != null)
        'last_exported_revision': lastExportedRevision,
      if (lastExportedAt != null) 'last_exported_at': lastExportedAt,
      if (reviewState != null) 'review_state': reviewState,
      if (sourceBatchId != null) 'source_batch_id': sourceBatchId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CasesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayCode,
    Value<int>? serialNo,
    Value<String>? caseTypeId,
    Value<DateTime>? occurredAt,
    Value<String?>? governorateId,
    Value<String?>? centerId,
    Value<String?>? locationText,
    Value<String?>? reportSourceId,
    Value<String?>? locationDescription,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? caseInfo,
    Value<String?>? actionTaken,
    Value<bool>? hasInjuries,
    Value<int>? injuriesCount,
    Value<bool>? hasDeaths,
    Value<int>? deathsCount,
    Value<bool>? hasDamage,
    Value<String?>? damageDescription,
    Value<String?>? notes,
    Value<String>? extraFieldsJson,
    Value<String?>? generatedText,
    Value<String?>? finalText,
    Value<bool>? isTextEdited,
    Value<String?>? enteredBy,
    Value<String?>? orgCode,
    Value<String>? originDeviceId,
    Value<int>? revision,
    Value<String?>? contentHash,
    Value<CaseStatus>? status,
    Value<int?>? lastExportedRevision,
    Value<DateTime?>? lastExportedAt,
    Value<ReviewState?>? reviewState,
    Value<String?>? sourceBatchId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CasesCompanion(
      id: id ?? this.id,
      displayCode: displayCode ?? this.displayCode,
      serialNo: serialNo ?? this.serialNo,
      caseTypeId: caseTypeId ?? this.caseTypeId,
      occurredAt: occurredAt ?? this.occurredAt,
      governorateId: governorateId ?? this.governorateId,
      centerId: centerId ?? this.centerId,
      locationText: locationText ?? this.locationText,
      reportSourceId: reportSourceId ?? this.reportSourceId,
      locationDescription: locationDescription ?? this.locationDescription,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      caseInfo: caseInfo ?? this.caseInfo,
      actionTaken: actionTaken ?? this.actionTaken,
      hasInjuries: hasInjuries ?? this.hasInjuries,
      injuriesCount: injuriesCount ?? this.injuriesCount,
      hasDeaths: hasDeaths ?? this.hasDeaths,
      deathsCount: deathsCount ?? this.deathsCount,
      hasDamage: hasDamage ?? this.hasDamage,
      damageDescription: damageDescription ?? this.damageDescription,
      notes: notes ?? this.notes,
      extraFieldsJson: extraFieldsJson ?? this.extraFieldsJson,
      generatedText: generatedText ?? this.generatedText,
      finalText: finalText ?? this.finalText,
      isTextEdited: isTextEdited ?? this.isTextEdited,
      enteredBy: enteredBy ?? this.enteredBy,
      orgCode: orgCode ?? this.orgCode,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      revision: revision ?? this.revision,
      contentHash: contentHash ?? this.contentHash,
      status: status ?? this.status,
      lastExportedRevision: lastExportedRevision ?? this.lastExportedRevision,
      lastExportedAt: lastExportedAt ?? this.lastExportedAt,
      reviewState: reviewState ?? this.reviewState,
      sourceBatchId: sourceBatchId ?? this.sourceBatchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayCode.present) {
      map['display_code'] = Variable<String>(displayCode.value);
    }
    if (serialNo.present) {
      map['serial_no'] = Variable<int>(serialNo.value);
    }
    if (caseTypeId.present) {
      map['case_type_id'] = Variable<String>(caseTypeId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (governorateId.present) {
      map['governorate_id'] = Variable<String>(governorateId.value);
    }
    if (centerId.present) {
      map['center_id'] = Variable<String>(centerId.value);
    }
    if (locationText.present) {
      map['location_text'] = Variable<String>(locationText.value);
    }
    if (reportSourceId.present) {
      map['report_source_id'] = Variable<String>(reportSourceId.value);
    }
    if (locationDescription.present) {
      map['location_description'] = Variable<String>(locationDescription.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (caseInfo.present) {
      map['case_info'] = Variable<String>(caseInfo.value);
    }
    if (actionTaken.present) {
      map['action_taken'] = Variable<String>(actionTaken.value);
    }
    if (hasInjuries.present) {
      map['has_injuries'] = Variable<bool>(hasInjuries.value);
    }
    if (injuriesCount.present) {
      map['injuries_count'] = Variable<int>(injuriesCount.value);
    }
    if (hasDeaths.present) {
      map['has_deaths'] = Variable<bool>(hasDeaths.value);
    }
    if (deathsCount.present) {
      map['deaths_count'] = Variable<int>(deathsCount.value);
    }
    if (hasDamage.present) {
      map['has_damage'] = Variable<bool>(hasDamage.value);
    }
    if (damageDescription.present) {
      map['damage_description'] = Variable<String>(damageDescription.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (extraFieldsJson.present) {
      map['extra_fields_json'] = Variable<String>(extraFieldsJson.value);
    }
    if (generatedText.present) {
      map['generated_text'] = Variable<String>(generatedText.value);
    }
    if (finalText.present) {
      map['final_text'] = Variable<String>(finalText.value);
    }
    if (isTextEdited.present) {
      map['is_text_edited'] = Variable<bool>(isTextEdited.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (orgCode.present) {
      map['org_code'] = Variable<String>(orgCode.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $CasesTable.$converterstatus.toSql(status.value),
      );
    }
    if (lastExportedRevision.present) {
      map['last_exported_revision'] = Variable<int>(lastExportedRevision.value);
    }
    if (lastExportedAt.present) {
      map['last_exported_at'] = Variable<DateTime>(lastExportedAt.value);
    }
    if (reviewState.present) {
      map['review_state'] = Variable<String>(
        $CasesTable.$converterreviewStaten.toSql(reviewState.value),
      );
    }
    if (sourceBatchId.present) {
      map['source_batch_id'] = Variable<String>(sourceBatchId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CasesCompanion(')
          ..write('id: $id, ')
          ..write('displayCode: $displayCode, ')
          ..write('serialNo: $serialNo, ')
          ..write('caseTypeId: $caseTypeId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('governorateId: $governorateId, ')
          ..write('centerId: $centerId, ')
          ..write('locationText: $locationText, ')
          ..write('reportSourceId: $reportSourceId, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('caseInfo: $caseInfo, ')
          ..write('actionTaken: $actionTaken, ')
          ..write('hasInjuries: $hasInjuries, ')
          ..write('injuriesCount: $injuriesCount, ')
          ..write('hasDeaths: $hasDeaths, ')
          ..write('deathsCount: $deathsCount, ')
          ..write('hasDamage: $hasDamage, ')
          ..write('damageDescription: $damageDescription, ')
          ..write('notes: $notes, ')
          ..write('extraFieldsJson: $extraFieldsJson, ')
          ..write('generatedText: $generatedText, ')
          ..write('finalText: $finalText, ')
          ..write('isTextEdited: $isTextEdited, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('orgCode: $orgCode, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('revision: $revision, ')
          ..write('contentHash: $contentHash, ')
          ..write('status: $status, ')
          ..write('lastExportedRevision: $lastExportedRevision, ')
          ..write('lastExportedAt: $lastExportedAt, ')
          ..write('reviewState: $reviewState, ')
          ..write('sourceBatchId: $sourceBatchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cases (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttachmentKind>($AttachmentsTable.$converterkind);
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbRelativePathMeta = const VerificationMeta(
    'thumbRelativePath',
  );
  @override
  late final GeneratedColumn<String> thumbRelativePath =
      GeneratedColumn<String>(
        'thumb_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseId,
    seq,
    kind,
    fileName,
    relativePath,
    thumbRelativePath,
    mimeType,
    sizeBytes,
    sha256,
    width,
    height,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('thumb_relative_path')) {
      context.handle(
        _thumbRelativePathMeta,
        thumbRelativePath.isAcceptableOrUnknown(
          data['thumb_relative_path']!,
          _thumbRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {caseId, seq},
  ];
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      kind: $AttachmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      thumbRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_relative_path'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttachmentKind, String, String> $converterkind =
      const EnumNameConverter<AttachmentKind>(AttachmentKind.values);
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String caseId;
  final int seq;
  final AttachmentKind kind;
  final String fileName;

  /// مسار نسبي داخل مجلد التطبيق الخاص — لا يُخزَّن مسار مطلق.
  final String relativePath;
  final String? thumbRelativePath;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final int? width;
  final int? height;
  final DateTime createdAt;
  final DateTime? deletedAt;
  const Attachment({
    required this.id,
    required this.caseId,
    required this.seq,
    required this.kind,
    required this.fileName,
    required this.relativePath,
    this.thumbRelativePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    this.width,
    this.height,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['seq'] = Variable<int>(seq);
    {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind),
      );
    }
    map['file_name'] = Variable<String>(fileName);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || thumbRelativePath != null) {
      map['thumb_relative_path'] = Variable<String>(thumbRelativePath);
    }
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['sha256'] = Variable<String>(sha256);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      seq: Value(seq),
      kind: Value(kind),
      fileName: Value(fileName),
      relativePath: Value(relativePath),
      thumbRelativePath: thumbRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbRelativePath),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      sha256: Value(sha256),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      seq: serializer.fromJson<int>(json['seq']),
      kind: $AttachmentsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      fileName: serializer.fromJson<String>(json['fileName']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      thumbRelativePath: serializer.fromJson<String?>(
        json['thumbRelativePath'],
      ),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sha256: serializer.fromJson<String>(json['sha256']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'seq': serializer.toJson<int>(seq),
      'kind': serializer.toJson<String>(
        $AttachmentsTable.$converterkind.toJson(kind),
      ),
      'fileName': serializer.toJson<String>(fileName),
      'relativePath': serializer.toJson<String>(relativePath),
      'thumbRelativePath': serializer.toJson<String?>(thumbRelativePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sha256': serializer.toJson<String>(sha256),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Attachment copyWith({
    String? id,
    String? caseId,
    int? seq,
    AttachmentKind? kind,
    String? fileName,
    String? relativePath,
    Value<String?> thumbRelativePath = const Value.absent(),
    String? mimeType,
    int? sizeBytes,
    String? sha256,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    seq: seq ?? this.seq,
    kind: kind ?? this.kind,
    fileName: fileName ?? this.fileName,
    relativePath: relativePath ?? this.relativePath,
    thumbRelativePath: thumbRelativePath.present
        ? thumbRelativePath.value
        : this.thumbRelativePath,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    sha256: sha256 ?? this.sha256,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      seq: data.seq.present ? data.seq.value : this.seq,
      kind: data.kind.present ? data.kind.value : this.kind,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      thumbRelativePath: data.thumbRelativePath.present
          ? data.thumbRelativePath.value
          : this.thumbRelativePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbRelativePath: $thumbRelativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    caseId,
    seq,
    kind,
    fileName,
    relativePath,
    thumbRelativePath,
    mimeType,
    sizeBytes,
    sha256,
    width,
    height,
    createdAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.seq == this.seq &&
          other.kind == this.kind &&
          other.fileName == this.fileName &&
          other.relativePath == this.relativePath &&
          other.thumbRelativePath == this.thumbRelativePath &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<int> seq;
  final Value<AttachmentKind> kind;
  final Value<String> fileName;
  final Value<String> relativePath;
  final Value<String?> thumbRelativePath;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String> sha256;
  final Value<int?> width;
  final Value<int?> height;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.seq = const Value.absent(),
    this.kind = const Value.absent(),
    this.fileName = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.thumbRelativePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String caseId,
    required int seq,
    required AttachmentKind kind,
    required String fileName,
    required String relativePath,
    this.thumbRelativePath = const Value.absent(),
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseId = Value(caseId),
       seq = Value(seq),
       kind = Value(kind),
       fileName = Value(fileName),
       relativePath = Value(relativePath),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       sha256 = Value(sha256),
       createdAt = Value(createdAt);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<int>? seq,
    Expression<String>? kind,
    Expression<String>? fileName,
    Expression<String>? relativePath,
    Expression<String>? thumbRelativePath,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<int>? width,
    Expression<int>? height,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (seq != null) 'seq': seq,
      if (kind != null) 'kind': kind,
      if (fileName != null) 'file_name': fileName,
      if (relativePath != null) 'relative_path': relativePath,
      if (thumbRelativePath != null) 'thumb_relative_path': thumbRelativePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? caseId,
    Value<int>? seq,
    Value<AttachmentKind>? kind,
    Value<String>? fileName,
    Value<String>? relativePath,
    Value<String?>? thumbRelativePath,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<String>? sha256,
    Value<int?>? width,
    Value<int?>? height,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      seq: seq ?? this.seq,
      kind: kind ?? this.kind,
      fileName: fileName ?? this.fileName,
      relativePath: relativePath ?? this.relativePath,
      thumbRelativePath: thumbRelativePath ?? this.thumbRelativePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind.value),
      );
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (thumbRelativePath.present) {
      map['thumb_relative_path'] = Variable<String>(thumbRelativePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbRelativePath: $thumbRelativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CasePartiesTable extends CaseParties
    with TableInfo<$CasePartiesTable, CaseParty> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CasePartiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cases (id)',
    ),
  );
  static const VerificationMeta _partyIdMeta = const VerificationMeta(
    'partyId',
  );
  @override
  late final GeneratedColumn<String> partyId = GeneratedColumn<String>(
    'party_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _notifiedAtMeta = const VerificationMeta(
    'notifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> notifiedAt = GeneratedColumn<DateTime>(
    'notified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [caseId, partyId, notifiedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'case_parties';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaseParty> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('party_id')) {
      context.handle(
        _partyIdMeta,
        partyId.isAcceptableOrUnknown(data['party_id']!, _partyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partyIdMeta);
    }
    if (data.containsKey('notified_at')) {
      context.handle(
        _notifiedAtMeta,
        notifiedAt.isAcceptableOrUnknown(data['notified_at']!, _notifiedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caseId, partyId};
  @override
  CaseParty map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaseParty(
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      partyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_id'],
      )!,
      notifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}notified_at'],
      ),
    );
  }

  @override
  $CasePartiesTable createAlias(String alias) {
    return $CasePartiesTable(attachedDatabase, alias);
  }
}

class CaseParty extends DataClass implements Insertable<CaseParty> {
  final String caseId;
  final String partyId;
  final DateTime? notifiedAt;
  const CaseParty({
    required this.caseId,
    required this.partyId,
    this.notifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['case_id'] = Variable<String>(caseId);
    map['party_id'] = Variable<String>(partyId);
    if (!nullToAbsent || notifiedAt != null) {
      map['notified_at'] = Variable<DateTime>(notifiedAt);
    }
    return map;
  }

  CasePartiesCompanion toCompanion(bool nullToAbsent) {
    return CasePartiesCompanion(
      caseId: Value(caseId),
      partyId: Value(partyId),
      notifiedAt: notifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(notifiedAt),
    );
  }

  factory CaseParty.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaseParty(
      caseId: serializer.fromJson<String>(json['caseId']),
      partyId: serializer.fromJson<String>(json['partyId']),
      notifiedAt: serializer.fromJson<DateTime?>(json['notifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caseId': serializer.toJson<String>(caseId),
      'partyId': serializer.toJson<String>(partyId),
      'notifiedAt': serializer.toJson<DateTime?>(notifiedAt),
    };
  }

  CaseParty copyWith({
    String? caseId,
    String? partyId,
    Value<DateTime?> notifiedAt = const Value.absent(),
  }) => CaseParty(
    caseId: caseId ?? this.caseId,
    partyId: partyId ?? this.partyId,
    notifiedAt: notifiedAt.present ? notifiedAt.value : this.notifiedAt,
  );
  CaseParty copyWithCompanion(CasePartiesCompanion data) {
    return CaseParty(
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      partyId: data.partyId.present ? data.partyId.value : this.partyId,
      notifiedAt: data.notifiedAt.present
          ? data.notifiedAt.value
          : this.notifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaseParty(')
          ..write('caseId: $caseId, ')
          ..write('partyId: $partyId, ')
          ..write('notifiedAt: $notifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(caseId, partyId, notifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaseParty &&
          other.caseId == this.caseId &&
          other.partyId == this.partyId &&
          other.notifiedAt == this.notifiedAt);
}

class CasePartiesCompanion extends UpdateCompanion<CaseParty> {
  final Value<String> caseId;
  final Value<String> partyId;
  final Value<DateTime?> notifiedAt;
  final Value<int> rowid;
  const CasePartiesCompanion({
    this.caseId = const Value.absent(),
    this.partyId = const Value.absent(),
    this.notifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CasePartiesCompanion.insert({
    required String caseId,
    required String partyId,
    this.notifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : caseId = Value(caseId),
       partyId = Value(partyId);
  static Insertable<CaseParty> custom({
    Expression<String>? caseId,
    Expression<String>? partyId,
    Expression<DateTime>? notifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caseId != null) 'case_id': caseId,
      if (partyId != null) 'party_id': partyId,
      if (notifiedAt != null) 'notified_at': notifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CasePartiesCompanion copyWith({
    Value<String>? caseId,
    Value<String>? partyId,
    Value<DateTime?>? notifiedAt,
    Value<int>? rowid,
  }) {
    return CasePartiesCompanion(
      caseId: caseId ?? this.caseId,
      partyId: partyId ?? this.partyId,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (partyId.present) {
      map['party_id'] = Variable<String>(partyId.value);
    }
    if (notifiedAt.present) {
      map['notified_at'] = Variable<DateTime>(notifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CasePartiesCompanion(')
          ..write('caseId: $caseId, ')
          ..write('partyId: $partyId, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CaseTypeFieldsTable extends CaseTypeFields
    with TableInfo<$CaseTypeFieldsTable, CaseTypeField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaseTypeFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseTypeIdMeta = const VerificationMeta(
    'caseTypeId',
  );
  @override
  late final GeneratedColumn<String> caseTypeId = GeneratedColumn<String>(
    'case_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FieldInputType, String>
  inputType = GeneratedColumn<String>(
    'input_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FieldInputType>($CaseTypeFieldsTable.$converterinputType);
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRequiredMeta = const VerificationMeta(
    'isRequired',
  );
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
    'is_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseTypeId,
    fieldKey,
    label,
    inputType,
    optionsJson,
    isRequired,
    sortOrder,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'case_type_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaseTypeField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_type_id')) {
      context.handle(
        _caseTypeIdMeta,
        caseTypeId.isAcceptableOrUnknown(
          data['case_type_id']!,
          _caseTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caseTypeIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_required')) {
      context.handle(
        _isRequiredMeta,
        isRequired.isAcceptableOrUnknown(data['is_required']!, _isRequiredMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {caseTypeId, fieldKey},
  ];
  @override
  CaseTypeField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaseTypeField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_type_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      inputType: $CaseTypeFieldsTable.$converterinputType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}input_type'],
        )!,
      ),
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      ),
      isRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $CaseTypeFieldsTable createAlias(String alias) {
    return $CaseTypeFieldsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FieldInputType, String, String>
  $converterinputType = const EnumNameConverter<FieldInputType>(
    FieldInputType.values,
  );
}

class CaseTypeField extends DataClass implements Insertable<CaseTypeField> {
  final String id;
  final String caseTypeId;
  final String fieldKey;
  final String label;
  final FieldInputType inputType;
  final String? optionsJson;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  const CaseTypeField({
    required this.id,
    required this.caseTypeId,
    required this.fieldKey,
    required this.label,
    required this.inputType,
    this.optionsJson,
    required this.isRequired,
    required this.sortOrder,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_type_id'] = Variable<String>(caseTypeId);
    map['field_key'] = Variable<String>(fieldKey);
    map['label'] = Variable<String>(label);
    {
      map['input_type'] = Variable<String>(
        $CaseTypeFieldsTable.$converterinputType.toSql(inputType),
      );
    }
    if (!nullToAbsent || optionsJson != null) {
      map['options_json'] = Variable<String>(optionsJson);
    }
    map['is_required'] = Variable<bool>(isRequired);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CaseTypeFieldsCompanion toCompanion(bool nullToAbsent) {
    return CaseTypeFieldsCompanion(
      id: Value(id),
      caseTypeId: Value(caseTypeId),
      fieldKey: Value(fieldKey),
      label: Value(label),
      inputType: Value(inputType),
      optionsJson: optionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(optionsJson),
      isRequired: Value(isRequired),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
    );
  }

  factory CaseTypeField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaseTypeField(
      id: serializer.fromJson<String>(json['id']),
      caseTypeId: serializer.fromJson<String>(json['caseTypeId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      label: serializer.fromJson<String>(json['label']),
      inputType: $CaseTypeFieldsTable.$converterinputType.fromJson(
        serializer.fromJson<String>(json['inputType']),
      ),
      optionsJson: serializer.fromJson<String?>(json['optionsJson']),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseTypeId': serializer.toJson<String>(caseTypeId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'label': serializer.toJson<String>(label),
      'inputType': serializer.toJson<String>(
        $CaseTypeFieldsTable.$converterinputType.toJson(inputType),
      ),
      'optionsJson': serializer.toJson<String?>(optionsJson),
      'isRequired': serializer.toJson<bool>(isRequired),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  CaseTypeField copyWith({
    String? id,
    String? caseTypeId,
    String? fieldKey,
    String? label,
    FieldInputType? inputType,
    Value<String?> optionsJson = const Value.absent(),
    bool? isRequired,
    int? sortOrder,
    bool? isActive,
  }) => CaseTypeField(
    id: id ?? this.id,
    caseTypeId: caseTypeId ?? this.caseTypeId,
    fieldKey: fieldKey ?? this.fieldKey,
    label: label ?? this.label,
    inputType: inputType ?? this.inputType,
    optionsJson: optionsJson.present ? optionsJson.value : this.optionsJson,
    isRequired: isRequired ?? this.isRequired,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
  );
  CaseTypeField copyWithCompanion(CaseTypeFieldsCompanion data) {
    return CaseTypeField(
      id: data.id.present ? data.id.value : this.id,
      caseTypeId: data.caseTypeId.present
          ? data.caseTypeId.value
          : this.caseTypeId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      label: data.label.present ? data.label.value : this.label,
      inputType: data.inputType.present ? data.inputType.value : this.inputType,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      isRequired: data.isRequired.present
          ? data.isRequired.value
          : this.isRequired,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaseTypeField(')
          ..write('id: $id, ')
          ..write('caseTypeId: $caseTypeId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label, ')
          ..write('inputType: $inputType, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('isRequired: $isRequired, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    caseTypeId,
    fieldKey,
    label,
    inputType,
    optionsJson,
    isRequired,
    sortOrder,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaseTypeField &&
          other.id == this.id &&
          other.caseTypeId == this.caseTypeId &&
          other.fieldKey == this.fieldKey &&
          other.label == this.label &&
          other.inputType == this.inputType &&
          other.optionsJson == this.optionsJson &&
          other.isRequired == this.isRequired &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive);
}

class CaseTypeFieldsCompanion extends UpdateCompanion<CaseTypeField> {
  final Value<String> id;
  final Value<String> caseTypeId;
  final Value<String> fieldKey;
  final Value<String> label;
  final Value<FieldInputType> inputType;
  final Value<String?> optionsJson;
  final Value<bool> isRequired;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<int> rowid;
  const CaseTypeFieldsCompanion({
    this.id = const Value.absent(),
    this.caseTypeId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.label = const Value.absent(),
    this.inputType = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaseTypeFieldsCompanion.insert({
    required String id,
    required String caseTypeId,
    required String fieldKey,
    required String label,
    required FieldInputType inputType,
    this.optionsJson = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseTypeId = Value(caseTypeId),
       fieldKey = Value(fieldKey),
       label = Value(label),
       inputType = Value(inputType);
  static Insertable<CaseTypeField> custom({
    Expression<String>? id,
    Expression<String>? caseTypeId,
    Expression<String>? fieldKey,
    Expression<String>? label,
    Expression<String>? inputType,
    Expression<String>? optionsJson,
    Expression<bool>? isRequired,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseTypeId != null) 'case_type_id': caseTypeId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (label != null) 'label': label,
      if (inputType != null) 'input_type': inputType,
      if (optionsJson != null) 'options_json': optionsJson,
      if (isRequired != null) 'is_required': isRequired,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaseTypeFieldsCompanion copyWith({
    Value<String>? id,
    Value<String>? caseTypeId,
    Value<String>? fieldKey,
    Value<String>? label,
    Value<FieldInputType>? inputType,
    Value<String?>? optionsJson,
    Value<bool>? isRequired,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return CaseTypeFieldsCompanion(
      id: id ?? this.id,
      caseTypeId: caseTypeId ?? this.caseTypeId,
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      inputType: inputType ?? this.inputType,
      optionsJson: optionsJson ?? this.optionsJson,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseTypeId.present) {
      map['case_type_id'] = Variable<String>(caseTypeId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (inputType.present) {
      map['input_type'] = Variable<String>(
        $CaseTypeFieldsTable.$converterinputType.toSql(inputType.value),
      );
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaseTypeFieldsCompanion(')
          ..write('id: $id, ')
          ..write('caseTypeId: $caseTypeId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label, ')
          ..write('inputType: $inputType, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('isRequired: $isRequired, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TextTemplatesTable extends TextTemplates
    with TableInfo<$TextTemplatesTable, TextTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TextTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseTypeIdMeta = const VerificationMeta(
    'caseTypeId',
  );
  @override
  late final GeneratedColumn<String> caseTypeId = GeneratedColumn<String>(
    'case_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lookup_items (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseTypeId,
    name,
    body,
    isDefault,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'text_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TextTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_type_id')) {
      context.handle(
        _caseTypeIdMeta,
        caseTypeId.isAcceptableOrUnknown(
          data['case_type_id']!,
          _caseTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TextTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TextTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_type_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TextTemplatesTable createAlias(String alias) {
    return $TextTemplatesTable(attachedDatabase, alias);
  }
}

class TextTemplate extends DataClass implements Insertable<TextTemplate> {
  final String id;
  final String? caseTypeId;
  final String name;
  final String body;
  final bool isDefault;
  final bool isActive;
  final DateTime updatedAt;
  const TextTemplate({
    required this.id,
    this.caseTypeId,
    required this.name,
    required this.body,
    required this.isDefault,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || caseTypeId != null) {
      map['case_type_id'] = Variable<String>(caseTypeId);
    }
    map['name'] = Variable<String>(name);
    map['body'] = Variable<String>(body);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TextTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TextTemplatesCompanion(
      id: Value(id),
      caseTypeId: caseTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(caseTypeId),
      name: Value(name),
      body: Value(body),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory TextTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TextTemplate(
      id: serializer.fromJson<String>(json['id']),
      caseTypeId: serializer.fromJson<String?>(json['caseTypeId']),
      name: serializer.fromJson<String>(json['name']),
      body: serializer.fromJson<String>(json['body']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseTypeId': serializer.toJson<String?>(caseTypeId),
      'name': serializer.toJson<String>(name),
      'body': serializer.toJson<String>(body),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TextTemplate copyWith({
    String? id,
    Value<String?> caseTypeId = const Value.absent(),
    String? name,
    String? body,
    bool? isDefault,
    bool? isActive,
    DateTime? updatedAt,
  }) => TextTemplate(
    id: id ?? this.id,
    caseTypeId: caseTypeId.present ? caseTypeId.value : this.caseTypeId,
    name: name ?? this.name,
    body: body ?? this.body,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TextTemplate copyWithCompanion(TextTemplatesCompanion data) {
    return TextTemplate(
      id: data.id.present ? data.id.value : this.id,
      caseTypeId: data.caseTypeId.present
          ? data.caseTypeId.value
          : this.caseTypeId,
      name: data.name.present ? data.name.value : this.name,
      body: data.body.present ? data.body.value : this.body,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TextTemplate(')
          ..write('id: $id, ')
          ..write('caseTypeId: $caseTypeId, ')
          ..write('name: $name, ')
          ..write('body: $body, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, caseTypeId, name, body, isDefault, isActive, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextTemplate &&
          other.id == this.id &&
          other.caseTypeId == this.caseTypeId &&
          other.name == this.name &&
          other.body == this.body &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class TextTemplatesCompanion extends UpdateCompanion<TextTemplate> {
  final Value<String> id;
  final Value<String?> caseTypeId;
  final Value<String> name;
  final Value<String> body;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TextTemplatesCompanion({
    this.id = const Value.absent(),
    this.caseTypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.body = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TextTemplatesCompanion.insert({
    required String id,
    this.caseTypeId = const Value.absent(),
    required String name,
    required String body,
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       body = Value(body),
       updatedAt = Value(updatedAt);
  static Insertable<TextTemplate> custom({
    Expression<String>? id,
    Expression<String>? caseTypeId,
    Expression<String>? name,
    Expression<String>? body,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseTypeId != null) 'case_type_id': caseTypeId,
      if (name != null) 'name': name,
      if (body != null) 'body': body,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TextTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String?>? caseTypeId,
    Value<String>? name,
    Value<String>? body,
    Value<bool>? isDefault,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TextTemplatesCompanion(
      id: id ?? this.id,
      caseTypeId: caseTypeId ?? this.caseTypeId,
      name: name ?? this.name,
      body: body ?? this.body,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseTypeId.present) {
      map['case_type_id'] = Variable<String>(caseTypeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TextTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('caseTypeId: $caseTypeId, ')
          ..write('name: $name, ')
          ..write('body: $body, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CaseVersionsTable extends CaseVersions
    with TableInfo<$CaseVersionsTable, CaseVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaseVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cases (id)',
    ),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VersionSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VersionSource>($CaseVersionsTable.$convertersource);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseId,
    revision,
    contentHash,
    snapshotJson,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'case_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaseVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaseVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaseVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
      source: $CaseVersionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CaseVersionsTable createAlias(String alias) {
    return $CaseVersionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<VersionSource, String, String> $convertersource =
      const EnumNameConverter<VersionSource>(VersionSource.values);
}

class CaseVersion extends DataClass implements Insertable<CaseVersion> {
  final String id;
  final String caseId;
  final int revision;
  final String contentHash;
  final String snapshotJson;
  final VersionSource source;
  final DateTime createdAt;
  const CaseVersion({
    required this.id,
    required this.caseId,
    required this.revision,
    required this.contentHash,
    required this.snapshotJson,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['revision'] = Variable<int>(revision);
    map['content_hash'] = Variable<String>(contentHash);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    {
      map['source'] = Variable<String>(
        $CaseVersionsTable.$convertersource.toSql(source),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CaseVersionsCompanion toCompanion(bool nullToAbsent) {
    return CaseVersionsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      revision: Value(revision),
      contentHash: Value(contentHash),
      snapshotJson: Value(snapshotJson),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory CaseVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaseVersion(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      revision: serializer.fromJson<int>(json['revision']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      source: $CaseVersionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'revision': serializer.toJson<int>(revision),
      'contentHash': serializer.toJson<String>(contentHash),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'source': serializer.toJson<String>(
        $CaseVersionsTable.$convertersource.toJson(source),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CaseVersion copyWith({
    String? id,
    String? caseId,
    int? revision,
    String? contentHash,
    String? snapshotJson,
    VersionSource? source,
    DateTime? createdAt,
  }) => CaseVersion(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    revision: revision ?? this.revision,
    contentHash: contentHash ?? this.contentHash,
    snapshotJson: snapshotJson ?? this.snapshotJson,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  CaseVersion copyWithCompanion(CaseVersionsCompanion data) {
    return CaseVersion(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      revision: data.revision.present ? data.revision.value : this.revision,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaseVersion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('revision: $revision, ')
          ..write('contentHash: $contentHash, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    caseId,
    revision,
    contentHash,
    snapshotJson,
    source,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaseVersion &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.revision == this.revision &&
          other.contentHash == this.contentHash &&
          other.snapshotJson == this.snapshotJson &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class CaseVersionsCompanion extends UpdateCompanion<CaseVersion> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<int> revision;
  final Value<String> contentHash;
  final Value<String> snapshotJson;
  final Value<VersionSource> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CaseVersionsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.revision = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaseVersionsCompanion.insert({
    required String id,
    required String caseId,
    required int revision,
    required String contentHash,
    required String snapshotJson,
    required VersionSource source,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseId = Value(caseId),
       revision = Value(revision),
       contentHash = Value(contentHash),
       snapshotJson = Value(snapshotJson),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<CaseVersion> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<int>? revision,
    Expression<String>? contentHash,
    Expression<String>? snapshotJson,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (revision != null) 'revision': revision,
      if (contentHash != null) 'content_hash': contentHash,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaseVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? caseId,
    Value<int>? revision,
    Value<String>? contentHash,
    Value<String>? snapshotJson,
    Value<VersionSource>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CaseVersionsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      revision: revision ?? this.revision,
      contentHash: contentHash ?? this.contentHash,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $CaseVersionsTable.$convertersource.toSql(source.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaseVersionsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('revision: $revision, ')
          ..write('contentHash: $contentHash, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportBatchesTable extends ExportBatches
    with TableInfo<$ExportBatchesTable, ExportBatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExportScope, String> scope =
      GeneratedColumn<String>(
        'scope',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExportScope>($ExportBatchesTable.$converterscope);
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseCountMeta = const VerificationMeta(
    'caseCount',
  );
  @override
  late final GeneratedColumn<int> caseCount = GeneratedColumn<int>(
    'case_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attachmentCountMeta = const VerificationMeta(
    'attachmentCount',
  );
  @override
  late final GeneratedColumn<int> attachmentCount = GeneratedColumn<int>(
    'attachment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageSha256Meta = const VerificationMeta(
    'packageSha256',
  );
  @override
  late final GeneratedColumn<String> packageSha256 = GeneratedColumn<String>(
    'package_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    scope,
    fileName,
    caseCount,
    attachmentCount,
    packageSha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportBatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('case_count')) {
      context.handle(
        _caseCountMeta,
        caseCount.isAcceptableOrUnknown(data['case_count']!, _caseCountMeta),
      );
    } else if (isInserting) {
      context.missing(_caseCountMeta);
    }
    if (data.containsKey('attachment_count')) {
      context.handle(
        _attachmentCountMeta,
        attachmentCount.isAcceptableOrUnknown(
          data['attachment_count']!,
          _attachmentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentCountMeta);
    }
    if (data.containsKey('package_sha256')) {
      context.handle(
        _packageSha256Meta,
        packageSha256.isAcceptableOrUnknown(
          data['package_sha256']!,
          _packageSha256Meta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportBatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportBatche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      scope: $ExportBatchesTable.$converterscope.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scope'],
        )!,
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      caseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}case_count'],
      )!,
      attachmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attachment_count'],
      )!,
      packageSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_sha256'],
      ),
    );
  }

  @override
  $ExportBatchesTable createAlias(String alias) {
    return $ExportBatchesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExportScope, String, String> $converterscope =
      const EnumNameConverter<ExportScope>(ExportScope.values);
}

class ExportBatche extends DataClass implements Insertable<ExportBatche> {
  /// = package_id في manifest.json
  final String id;
  final DateTime createdAt;
  final ExportScope scope;
  final String fileName;
  final int caseCount;
  final int attachmentCount;
  final String? packageSha256;
  const ExportBatche({
    required this.id,
    required this.createdAt,
    required this.scope,
    required this.fileName,
    required this.caseCount,
    required this.attachmentCount,
    this.packageSha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['scope'] = Variable<String>(
        $ExportBatchesTable.$converterscope.toSql(scope),
      );
    }
    map['file_name'] = Variable<String>(fileName);
    map['case_count'] = Variable<int>(caseCount);
    map['attachment_count'] = Variable<int>(attachmentCount);
    if (!nullToAbsent || packageSha256 != null) {
      map['package_sha256'] = Variable<String>(packageSha256);
    }
    return map;
  }

  ExportBatchesCompanion toCompanion(bool nullToAbsent) {
    return ExportBatchesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      scope: Value(scope),
      fileName: Value(fileName),
      caseCount: Value(caseCount),
      attachmentCount: Value(attachmentCount),
      packageSha256: packageSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(packageSha256),
    );
  }

  factory ExportBatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportBatche(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      scope: $ExportBatchesTable.$converterscope.fromJson(
        serializer.fromJson<String>(json['scope']),
      ),
      fileName: serializer.fromJson<String>(json['fileName']),
      caseCount: serializer.fromJson<int>(json['caseCount']),
      attachmentCount: serializer.fromJson<int>(json['attachmentCount']),
      packageSha256: serializer.fromJson<String?>(json['packageSha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'scope': serializer.toJson<String>(
        $ExportBatchesTable.$converterscope.toJson(scope),
      ),
      'fileName': serializer.toJson<String>(fileName),
      'caseCount': serializer.toJson<int>(caseCount),
      'attachmentCount': serializer.toJson<int>(attachmentCount),
      'packageSha256': serializer.toJson<String?>(packageSha256),
    };
  }

  ExportBatche copyWith({
    String? id,
    DateTime? createdAt,
    ExportScope? scope,
    String? fileName,
    int? caseCount,
    int? attachmentCount,
    Value<String?> packageSha256 = const Value.absent(),
  }) => ExportBatche(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    scope: scope ?? this.scope,
    fileName: fileName ?? this.fileName,
    caseCount: caseCount ?? this.caseCount,
    attachmentCount: attachmentCount ?? this.attachmentCount,
    packageSha256: packageSha256.present
        ? packageSha256.value
        : this.packageSha256,
  );
  ExportBatche copyWithCompanion(ExportBatchesCompanion data) {
    return ExportBatche(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      scope: data.scope.present ? data.scope.value : this.scope,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      caseCount: data.caseCount.present ? data.caseCount.value : this.caseCount,
      attachmentCount: data.attachmentCount.present
          ? data.attachmentCount.value
          : this.attachmentCount,
      packageSha256: data.packageSha256.present
          ? data.packageSha256.value
          : this.packageSha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatche(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('scope: $scope, ')
          ..write('fileName: $fileName, ')
          ..write('caseCount: $caseCount, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('packageSha256: $packageSha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    scope,
    fileName,
    caseCount,
    attachmentCount,
    packageSha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportBatche &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.scope == this.scope &&
          other.fileName == this.fileName &&
          other.caseCount == this.caseCount &&
          other.attachmentCount == this.attachmentCount &&
          other.packageSha256 == this.packageSha256);
}

class ExportBatchesCompanion extends UpdateCompanion<ExportBatche> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<ExportScope> scope;
  final Value<String> fileName;
  final Value<int> caseCount;
  final Value<int> attachmentCount;
  final Value<String?> packageSha256;
  final Value<int> rowid;
  const ExportBatchesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.scope = const Value.absent(),
    this.fileName = const Value.absent(),
    this.caseCount = const Value.absent(),
    this.attachmentCount = const Value.absent(),
    this.packageSha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportBatchesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required ExportScope scope,
    required String fileName,
    required int caseCount,
    required int attachmentCount,
    this.packageSha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       scope = Value(scope),
       fileName = Value(fileName),
       caseCount = Value(caseCount),
       attachmentCount = Value(attachmentCount);
  static Insertable<ExportBatche> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? scope,
    Expression<String>? fileName,
    Expression<int>? caseCount,
    Expression<int>? attachmentCount,
    Expression<String>? packageSha256,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (scope != null) 'scope': scope,
      if (fileName != null) 'file_name': fileName,
      if (caseCount != null) 'case_count': caseCount,
      if (attachmentCount != null) 'attachment_count': attachmentCount,
      if (packageSha256 != null) 'package_sha256': packageSha256,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportBatchesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<ExportScope>? scope,
    Value<String>? fileName,
    Value<int>? caseCount,
    Value<int>? attachmentCount,
    Value<String?>? packageSha256,
    Value<int>? rowid,
  }) {
    return ExportBatchesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      scope: scope ?? this.scope,
      fileName: fileName ?? this.fileName,
      caseCount: caseCount ?? this.caseCount,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      packageSha256: packageSha256 ?? this.packageSha256,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(
        $ExportBatchesTable.$converterscope.toSql(scope.value),
      );
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (caseCount.present) {
      map['case_count'] = Variable<int>(caseCount.value);
    }
    if (attachmentCount.present) {
      map['attachment_count'] = Variable<int>(attachmentCount.value);
    }
    if (packageSha256.present) {
      map['package_sha256'] = Variable<String>(packageSha256.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatchesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('scope: $scope, ')
          ..write('fileName: $fileName, ')
          ..write('caseCount: $caseCount, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('packageSha256: $packageSha256, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportBatchItemsTable extends ExportBatchItems
    with TableInfo<$ExportBatchItemsTable, ExportBatchItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportBatchItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES export_batches (id)',
    ),
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cases (id)',
    ),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [batchId, caseId, revision];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_batch_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportBatchItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId, caseId};
  @override
  ExportBatchItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportBatchItem(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $ExportBatchItemsTable createAlias(String alias) {
    return $ExportBatchItemsTable(attachedDatabase, alias);
  }
}

class ExportBatchItem extends DataClass implements Insertable<ExportBatchItem> {
  final String batchId;
  final String caseId;
  final int revision;
  const ExportBatchItem({
    required this.batchId,
    required this.caseId,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<String>(batchId);
    map['case_id'] = Variable<String>(caseId);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ExportBatchItemsCompanion toCompanion(bool nullToAbsent) {
    return ExportBatchItemsCompanion(
      batchId: Value(batchId),
      caseId: Value(caseId),
      revision: Value(revision),
    );
  }

  factory ExportBatchItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportBatchItem(
      batchId: serializer.fromJson<String>(json['batchId']),
      caseId: serializer.fromJson<String>(json['caseId']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batchId': serializer.toJson<String>(batchId),
      'caseId': serializer.toJson<String>(caseId),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ExportBatchItem copyWith({String? batchId, String? caseId, int? revision}) =>
      ExportBatchItem(
        batchId: batchId ?? this.batchId,
        caseId: caseId ?? this.caseId,
        revision: revision ?? this.revision,
      );
  ExportBatchItem copyWithCompanion(ExportBatchItemsCompanion data) {
    return ExportBatchItem(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatchItem(')
          ..write('batchId: $batchId, ')
          ..write('caseId: $caseId, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(batchId, caseId, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportBatchItem &&
          other.batchId == this.batchId &&
          other.caseId == this.caseId &&
          other.revision == this.revision);
}

class ExportBatchItemsCompanion extends UpdateCompanion<ExportBatchItem> {
  final Value<String> batchId;
  final Value<String> caseId;
  final Value<int> revision;
  final Value<int> rowid;
  const ExportBatchItemsCompanion({
    this.batchId = const Value.absent(),
    this.caseId = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportBatchItemsCompanion.insert({
    required String batchId,
    required String caseId,
    required int revision,
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       caseId = Value(caseId),
       revision = Value(revision);
  static Insertable<ExportBatchItem> custom({
    Expression<String>? batchId,
    Expression<String>? caseId,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (caseId != null) 'case_id': caseId,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportBatchItemsCompanion copyWith({
    Value<String>? batchId,
    Value<String>? caseId,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ExportBatchItemsCompanion(
      batchId: batchId ?? this.batchId,
      caseId: caseId ?? this.caseId,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatchItemsCompanion(')
          ..write('batchId: $batchId, ')
          ..write('caseId: $caseId, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportBatchItemsTable extends ImportBatchItems
    with TableInfo<$ImportBatchItemsTable, ImportBatchItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportBatchItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES import_batches (id)',
    ),
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incomingRevisionMeta = const VerificationMeta(
    'incomingRevision',
  );
  @override
  late final GeneratedColumn<int> incomingRevision = GeneratedColumn<int>(
    'incoming_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImportClassification, String>
  classification =
      GeneratedColumn<String>(
        'classification',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ImportClassification>(
        $ImportBatchItemsTable.$converterclassification,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ImportDecision, String> decision =
      GeneratedColumn<String>(
        'decision',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ImportDecision>(
        $ImportBatchItemsTable.$converterdecision,
      );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    batchId,
    caseId,
    incomingRevision,
    classification,
    decision,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_batch_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportBatchItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('incoming_revision')) {
      context.handle(
        _incomingRevisionMeta,
        incomingRevision.isAcceptableOrUnknown(
          data['incoming_revision']!,
          _incomingRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_incomingRevisionMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId, caseId};
  @override
  ImportBatchItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportBatchItem(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      incomingRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incoming_revision'],
      )!,
      classification: $ImportBatchItemsTable.$converterclassification.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}classification'],
        )!,
      ),
      decision: $ImportBatchItemsTable.$converterdecision.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}decision'],
        )!,
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $ImportBatchItemsTable createAlias(String alias) {
    return $ImportBatchItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ImportClassification, String, String>
  $converterclassification = const EnumNameConverter<ImportClassification>(
    ImportClassification.values,
  );
  static JsonTypeConverter2<ImportDecision, String, String> $converterdecision =
      const EnumNameConverter<ImportDecision>(ImportDecision.values);
}

class ImportBatchItem extends DataClass implements Insertable<ImportBatchItem> {
  final String batchId;

  /// لا يوجد FK هنا: الحالة قد تكون مرفوضة/متجاهلة فلا تُدرج في cases.
  final String caseId;
  final int incomingRevision;
  final ImportClassification classification;
  final ImportDecision decision;
  final String? errorMessage;
  const ImportBatchItem({
    required this.batchId,
    required this.caseId,
    required this.incomingRevision,
    required this.classification,
    required this.decision,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<String>(batchId);
    map['case_id'] = Variable<String>(caseId);
    map['incoming_revision'] = Variable<int>(incomingRevision);
    {
      map['classification'] = Variable<String>(
        $ImportBatchItemsTable.$converterclassification.toSql(classification),
      );
    }
    {
      map['decision'] = Variable<String>(
        $ImportBatchItemsTable.$converterdecision.toSql(decision),
      );
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ImportBatchItemsCompanion toCompanion(bool nullToAbsent) {
    return ImportBatchItemsCompanion(
      batchId: Value(batchId),
      caseId: Value(caseId),
      incomingRevision: Value(incomingRevision),
      classification: Value(classification),
      decision: Value(decision),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ImportBatchItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportBatchItem(
      batchId: serializer.fromJson<String>(json['batchId']),
      caseId: serializer.fromJson<String>(json['caseId']),
      incomingRevision: serializer.fromJson<int>(json['incomingRevision']),
      classification: $ImportBatchItemsTable.$converterclassification.fromJson(
        serializer.fromJson<String>(json['classification']),
      ),
      decision: $ImportBatchItemsTable.$converterdecision.fromJson(
        serializer.fromJson<String>(json['decision']),
      ),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batchId': serializer.toJson<String>(batchId),
      'caseId': serializer.toJson<String>(caseId),
      'incomingRevision': serializer.toJson<int>(incomingRevision),
      'classification': serializer.toJson<String>(
        $ImportBatchItemsTable.$converterclassification.toJson(classification),
      ),
      'decision': serializer.toJson<String>(
        $ImportBatchItemsTable.$converterdecision.toJson(decision),
      ),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ImportBatchItem copyWith({
    String? batchId,
    String? caseId,
    int? incomingRevision,
    ImportClassification? classification,
    ImportDecision? decision,
    Value<String?> errorMessage = const Value.absent(),
  }) => ImportBatchItem(
    batchId: batchId ?? this.batchId,
    caseId: caseId ?? this.caseId,
    incomingRevision: incomingRevision ?? this.incomingRevision,
    classification: classification ?? this.classification,
    decision: decision ?? this.decision,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  ImportBatchItem copyWithCompanion(ImportBatchItemsCompanion data) {
    return ImportBatchItem(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      incomingRevision: data.incomingRevision.present
          ? data.incomingRevision.value
          : this.incomingRevision,
      classification: data.classification.present
          ? data.classification.value
          : this.classification,
      decision: data.decision.present ? data.decision.value : this.decision,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatchItem(')
          ..write('batchId: $batchId, ')
          ..write('caseId: $caseId, ')
          ..write('incomingRevision: $incomingRevision, ')
          ..write('classification: $classification, ')
          ..write('decision: $decision, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    batchId,
    caseId,
    incomingRevision,
    classification,
    decision,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportBatchItem &&
          other.batchId == this.batchId &&
          other.caseId == this.caseId &&
          other.incomingRevision == this.incomingRevision &&
          other.classification == this.classification &&
          other.decision == this.decision &&
          other.errorMessage == this.errorMessage);
}

class ImportBatchItemsCompanion extends UpdateCompanion<ImportBatchItem> {
  final Value<String> batchId;
  final Value<String> caseId;
  final Value<int> incomingRevision;
  final Value<ImportClassification> classification;
  final Value<ImportDecision> decision;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const ImportBatchItemsCompanion({
    this.batchId = const Value.absent(),
    this.caseId = const Value.absent(),
    this.incomingRevision = const Value.absent(),
    this.classification = const Value.absent(),
    this.decision = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportBatchItemsCompanion.insert({
    required String batchId,
    required String caseId,
    required int incomingRevision,
    required ImportClassification classification,
    required ImportDecision decision,
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       caseId = Value(caseId),
       incomingRevision = Value(incomingRevision),
       classification = Value(classification),
       decision = Value(decision);
  static Insertable<ImportBatchItem> custom({
    Expression<String>? batchId,
    Expression<String>? caseId,
    Expression<int>? incomingRevision,
    Expression<String>? classification,
    Expression<String>? decision,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (caseId != null) 'case_id': caseId,
      if (incomingRevision != null) 'incoming_revision': incomingRevision,
      if (classification != null) 'classification': classification,
      if (decision != null) 'decision': decision,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportBatchItemsCompanion copyWith({
    Value<String>? batchId,
    Value<String>? caseId,
    Value<int>? incomingRevision,
    Value<ImportClassification>? classification,
    Value<ImportDecision>? decision,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return ImportBatchItemsCompanion(
      batchId: batchId ?? this.batchId,
      caseId: caseId ?? this.caseId,
      incomingRevision: incomingRevision ?? this.incomingRevision,
      classification: classification ?? this.classification,
      decision: decision ?? this.decision,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (incomingRevision.present) {
      map['incoming_revision'] = Variable<int>(incomingRevision.value);
    }
    if (classification.present) {
      map['classification'] = Variable<String>(
        $ImportBatchItemsTable.$converterclassification.toSql(
          classification.value,
        ),
      );
    }
    if (decision.present) {
      map['decision'] = Variable<String>(
        $ImportBatchItemsTable.$converterdecision.toSql(decision.value),
      );
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatchItemsCompanion(')
          ..write('batchId: $batchId, ')
          ..write('caseId: $caseId, ')
          ..write('incomingRevision: $incomingRevision, ')
          ..write('classification: $classification, ')
          ..write('decision: $decision, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsJsonMeta = const VerificationMeta(
    'detailsJson',
  );
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
    'details_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    action,
    entityType,
    entityId,
    detailsJson,
    actor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('details_json')) {
      context.handle(
        _detailsJsonMeta,
        detailsJson.isAcceptableOrUnknown(
          data['details_json']!,
          _detailsJsonMeta,
        ),
      );
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      detailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details_json'],
      ),
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      ),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  final int id;
  final DateTime at;
  final String action;
  final String entityType;
  final String? entityId;
  final String? detailsJson;
  final String? actor;
  const AuditLogData({
    required this.id,
    required this.at,
    required this.action,
    required this.entityType,
    this.entityId,
    this.detailsJson,
    this.actor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || detailsJson != null) {
      map['details_json'] = Variable<String>(detailsJson);
    }
    if (!nullToAbsent || actor != null) {
      map['actor'] = Variable<String>(actor);
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      at: Value(at),
      action: Value(action),
      entityType: Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      detailsJson: detailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailsJson),
      actor: actor == null && nullToAbsent
          ? const Value.absent()
          : Value(actor),
    );
  }

  factory AuditLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      detailsJson: serializer.fromJson<String?>(json['detailsJson']),
      actor: serializer.fromJson<String?>(json['actor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'detailsJson': serializer.toJson<String?>(detailsJson),
      'actor': serializer.toJson<String?>(actor),
    };
  }

  AuditLogData copyWith({
    int? id,
    DateTime? at,
    String? action,
    String? entityType,
    Value<String?> entityId = const Value.absent(),
    Value<String?> detailsJson = const Value.absent(),
    Value<String?> actor = const Value.absent(),
  }) => AuditLogData(
    id: id ?? this.id,
    at: at ?? this.at,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    detailsJson: detailsJson.present ? detailsJson.value : this.detailsJson,
    actor: actor.present ? actor.value : this.actor,
  );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      detailsJson: data.detailsJson.present
          ? data.detailsJson.value
          : this.detailsJson,
      actor: data.actor.present ? data.actor.value : this.actor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('actor: $actor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, at, action, entityType, entityId, detailsJson, actor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.at == this.at &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.detailsJson == this.detailsJson &&
          other.actor == this.actor);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String?> entityId;
  final Value<String?> detailsJson;
  final Value<String?> actor;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.actor = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String action,
    required String entityType,
    this.entityId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.actor = const Value.absent(),
  }) : at = Value(at),
       action = Value(action),
       entityType = Value(entityType);
  static Insertable<AuditLogData> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? detailsJson,
    Expression<String>? actor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (detailsJson != null) 'details_json': detailsJson,
      if (actor != null) 'actor': actor,
    });
  }

  AuditLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? action,
    Value<String>? entityType,
    Value<String?>? entityId,
    Value<String?>? detailsJson,
    Value<String?>? actor,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      detailsJson: detailsJson ?? this.detailsJson,
      actor: actor ?? this.actor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('actor: $actor')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $LookupItemsTable lookupItems = $LookupItemsTable(this);
  late final $ImportBatchesTable importBatches = $ImportBatchesTable(this);
  late final $CasesTable cases = $CasesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $CasePartiesTable caseParties = $CasePartiesTable(this);
  late final $CaseTypeFieldsTable caseTypeFields = $CaseTypeFieldsTable(this);
  late final $TextTemplatesTable textTemplates = $TextTemplatesTable(this);
  late final $CaseVersionsTable caseVersions = $CaseVersionsTable(this);
  late final $ExportBatchesTable exportBatches = $ExportBatchesTable(this);
  late final $ExportBatchItemsTable exportBatchItems = $ExportBatchItemsTable(
    this,
  );
  late final $ImportBatchItemsTable importBatchItems = $ImportBatchItemsTable(
    this,
  );
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index idxLookupList = Index(
    'idx_lookup_list',
    'CREATE INDEX idx_lookup_list ON lookup_items (list_key, is_active, sort_order)',
  );
  late final Index idxCasesActiveOccurred = Index(
    'idx_cases_active_occurred',
    'CREATE INDEX idx_cases_active_occurred ON cases (deleted_at, occurred_at DESC)',
  );
  late final Index idxCasesDisplayCode = Index(
    'idx_cases_display_code',
    'CREATE INDEX idx_cases_display_code ON cases (display_code)',
  );
  late final Index idxCasesStatus = Index(
    'idx_cases_status',
    'CREATE INDEX idx_cases_status ON cases (status)',
  );
  late final Index idxCasesType = Index(
    'idx_cases_type',
    'CREATE INDEX idx_cases_type ON cases (case_type_id)',
  );
  late final Index idxCasesGovernorate = Index(
    'idx_cases_governorate',
    'CREATE INDEX idx_cases_governorate ON cases (governorate_id)',
  );
  late final Index idxCasesReview = Index(
    'idx_cases_review',
    'CREATE INDEX idx_cases_review ON cases (review_state)',
  );
  late final Index idxCasesBatch = Index(
    'idx_cases_batch',
    'CREATE INDEX idx_cases_batch ON cases (source_batch_id)',
  );
  late final Index idxAttachmentsCase = Index(
    'idx_attachments_case',
    'CREATE INDEX idx_attachments_case ON attachments (case_id, seq)',
  );
  late final Index idxTypeFields = Index(
    'idx_type_fields',
    'CREATE INDEX idx_type_fields ON case_type_fields (case_type_id, sort_order)',
  );
  late final Index idxVersionsCase = Index(
    'idx_versions_case',
    'CREATE INDEX idx_versions_case ON case_versions (case_id, revision)',
  );
  late final Index idxAuditAt = Index(
    'idx_audit_at',
    'CREATE INDEX idx_audit_at ON audit_log (at)',
  );
  late final Index idxAuditEntity = Index(
    'idx_audit_entity',
    'CREATE INDEX idx_audit_entity ON audit_log (entity_type, entity_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lookupItems,
    importBatches,
    cases,
    attachments,
    caseParties,
    caseTypeFields,
    textTemplates,
    caseVersions,
    exportBatches,
    exportBatchItems,
    importBatchItems,
    auditLog,
    appSettings,
    idxLookupList,
    idxCasesActiveOccurred,
    idxCasesDisplayCode,
    idxCasesStatus,
    idxCasesType,
    idxCasesGovernorate,
    idxCasesReview,
    idxCasesBatch,
    idxAttachmentsCase,
    idxTypeFields,
    idxVersionsCase,
    idxAuditAt,
    idxAuditEntity,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
