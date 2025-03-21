int BXGetInt(value){
  return (value ?? 0)?.toInt();
}
String BXGetString(value){
  if(value is int){
    value = value.toString();
  }else if(value is double){
    value = BXGetDouble(value);
  }
  return value ?? "";
}
List<T> BXGetList<T>(value,{onModel}){
  if(onModel != null){
    List<T> values = [];
    for (var element in ((value ?? []) as List)) {
      values.add(onModel(element));
    }
    return values;
  }else{
    return value ?? [];
  }
}

bool BXGetBool(dynamic value) => value ?? false;

String BXGetDouble(value,{int position = 2}){
  if(value == null){
    return "0";
  }
  if(value is int){
    return "$value";
  }
  return ((value ?? 0.00) as double).toStringAsFixed(position + 1).substring(0,value.toString().split(".").first.length + position + 1);
}

double BXGetDoubleOrInt(value) {
  if (value != null && value is int) {
    return value.toDouble();
  } else {
    return value;
  }
}