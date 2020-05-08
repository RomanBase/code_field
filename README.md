Widget providing input code field to insert pin, sms and other auth codes.\
Also can be used for time/date or any highly formatted input.

**[InputCodeControl]** handles all logic parts, validation, holds current value and index pointer to next field. InputCodeControl is **[StateControl]** so other widgets can subscribe and listen about changes.\
And provides Keyboard Action Event and automatically fires this event when code is filled. Can be used to validate code or to focus next field.

Standard **[InputCodeField]** is drawn with underline and can be customized with **[InputCodeDecoration]**. Supports enable/disable state, obscuring, sizing, coloring, etc..

![Structure](https://raw.githubusercontent.com/RomanBase/code_field/master/doc/code.png)

For better visual control is used **itemBuilder** to build custom Code Field Item. Builder providing BuildContext and index of current field.\
To get char at given index use **[]** operator on **[InputCodeControl]**.\
To check if item has focus use **InputCodeControl.isFocused(index)**.

```dart
InputCodeField(
  control: codeControl
  itemBuilder: (context, index) => CustomCodeItem(
    char: codeControl[index],
    focused: codeControl.isFocused(index),
    ),
);


class CustomCodeItem extends StatelessWidget {
  final String char;
  final bool focused;

  const CustomCodeItem({
    Key key,
    this.char: '',
    this.focused: false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.0,
      height: 42.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: focused ? Colors.grey : Colors.grey.withOpacity(0.25),
        border: Border.all(color: focused ? Colors.black : Colors.grey),
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

For total visual control use **builder** to build whole input widget. **[InputCodeField]** and **[InputCodeControl]** still handles all input logic and keyboard actions.

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
- tests and documentation
- overriding/editing from middle
- copy/paste toolbar