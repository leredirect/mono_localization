enum ElementType { literal, argument, plural, gender, select }

class BaseElement {

  BaseElement(this.type, this.value);
  ElementType type;
  String value;
}

class Option {

  Option(this.name, this.value);
  String name;
  List<BaseElement> value;
}

class LiteralElement extends BaseElement {
  LiteralElement(String value) : super(ElementType.literal, value);
}

class ArgumentElement extends BaseElement {
  ArgumentElement(String value) : super(ElementType.argument, value);
}

class GenderElement extends BaseElement {

  GenderElement(String value, this.options) : super(ElementType.gender, value);
  List<Option> options;
}

class PluralElement extends BaseElement {

  PluralElement(String value, this.options) : super(ElementType.plural, value);
  List<Option> options;
}

class SelectElement extends BaseElement {

  SelectElement(String value, this.options) : super(ElementType.select, value);
  List<Option> options;
}
