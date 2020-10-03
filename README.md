Widget providing input code field to insert pin, sms and other auth codes.\
Also can be used for time/date or any highly formatted input.\
And supports **backspace** keyboard button.

```dart
import 'package:code_field/code_field.dart';
```

`InputCodeControl` handles all logic parts, input validation, holds current value and index pointer to next field.\

Standard `InputCodeField` is drawn with underline and can be customized with `InputCodeDecoration`. Supports enable/disable state, obscuring, sizing, coloring, etc..

```dart
final codeControl = InputCodeControl(inputRegex: '^[0-9]*$');

InputCodeField(
  control: codeControl,
  count: 6,
  inputType: TextInputType.number,
  decoration: InputCodeDecoration(
    focusColor: Colors.blueGrey,
  ),
),
```

![Structure](https://raw.githubusercontent.com/RomanBase/code_field/master/doc/code.png)

For better visual control can be used **itemBuilder** to build custom Field Item.\
To get char at given index use `[]` operator on **InputCodeControl**.\
To check if item at given index is focused use `InputCodeControl.isFocused(index)` and `InputCodeControl.hasFocus` to check if whole Widget has focus.

```dart
InputCodeField(
  control: codeControl
  itemBuilder: (context, index) => CustomCodeItem(
      char: control.stringCode.code[index],
      fieldFocused: codeControl.hasFocus,
      itemFocused: codeControl.isFocused(index),
    ),
);


class CustomCodeItem extends StatelessWidget {
  final String char;
  final bool fieldFocused;
  final bool itemFocused;

  const CustomCodeItem({
    Key key,
    this.char: '',
    this.fieldFocused: false,
    this.itemFocused: false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.0,
      height: 42.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: fieldFocused ? (itemFocused ? Colors.grey : Colors.grey.withOpacity(0.5)) : Colors.grey.withOpacity(0.25),
        border: Border.all(color: itemFocused ? Colors.black : Colors.grey),
      ),
      child: Center(
        child: Text(
          char,
          style: Theme.of(context).primaryTextTheme.headline4,
        ),
      ),
    );
  }
}
```

![Structure](https://raw.githubusercontent.com/RomanBase/code_field/master/doc/code_item.png)

For total visual control use **builder** to build whole input widget. `InputCodeField` and `InputCodeControl` still handles all input logic and keyboard actions.

```dart
InputCodeField(
  control: codeControl
  builder: (context) => CustomCodeField(
    control: codeControl,
    ),
);


class CustomCodeField extends StatelessWidget {
  final InputCodeControl control;

  const CustomCodeField({
    Key key,
    this.control,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = List<Widget>();

    for (int i = 0; i < control.count; i++) {
      if (i > 0 && i % 3 == 0) {
        items.add(Container(
          margin: EdgeInsets.symmetric(horizontal: 24.0),
          height: 32.0,
          width: 2.0,
          color: control.hasFocus ? Colors.green : Colors.blueGrey,
        ));

        items.add(Container(
          height: 42,
          width: 1.0,
          color: Colors.blueGrey,
        ));
      }

      items.add(Expanded(
        child: Container(
          height: 42.0,
          color: control.isFocused(i, true) ? Colors.greenAccent.withOpacity(0.25) : Colors.transparent,
          child: Center(
            child: Text(
              control[i],
              style: Theme.of(context).primaryTextTheme.headline4,
            ),
          ),
        ),
      ));

      if (i < control.count - 1) {
        items.add(Container(
          height: 42,
          width: 1.0,
          color: Colors.blueGrey,
        ));
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: control.hasFocus ? Colors.green : Colors.blueGrey),
        ),
        child: Row(
          children: items,
        ),
      ),
    );
  }
}
```

![Structure](https://raw.githubusercontent.com/RomanBase/code_field/master/doc/code_widget.png)

**What's missing:**
- overriding/editing from middle
- copy/paste toolbar