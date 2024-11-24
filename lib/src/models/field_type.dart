final Map<String, dynamic> type_map = {
  'STRING': FieldType.STRING,
  'NUMBER': FieldType.NUMBER,
  'BOOLEAN': FieldType.BOOLEAN,
  'UNKNOWN': FieldType.UNKNOWN,
  'BUCKET': FieldType.MAP,
  'ARRAY': FieldType.ARRAY
};


class FieldType{
  static final FieldType STRING = FieldType(1, "STRING");
  static final FieldType NUMBER = FieldType(2, "NUMBER");
  static final FieldType BOOLEAN = FieldType(3, "BOOLEAN");
  static final FieldType UNKNOWN = FieldType(-1, "UNKNOWN");
  static final FieldType MAP = FieldType(4, 'BUCKET');
  static final FieldType ARRAY = FieldType(5, 'ARRAY');

  String type;
  int id;

  FieldType(this.id, this.type);

  isBasic(){
    if (this.type == "STRING" || this.type == "NUMBER" || this.type == "BOOLEAN"){
      return true;
    }
    return false;
  }
}