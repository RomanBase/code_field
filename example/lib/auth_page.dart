import 'package:code_field/code_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

import 'auth_control.dart';

class AuthPage extends SingleControlWidget<AuthControl> with ThemeProvider {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Code Field Example'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Submit Code',
              style: font.headline2,
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AuthCodeField(
                  model: control.numberCode,
                ),
              ),
              NotifierBuilder<InputCodeControl>(
                control: control.numberCode.code,
                builder: (context, value) {
                  return RaisedButton(
                    onPressed: control.numberCode.toggleObscure,
                    child: Icon(value.isObscured
                        ? Icons.visibility_off
                        : Icons.visibility),
                  );
                },
              ),
            ],
          ),
          SizedBox(
            height: 48.0,
          ),
          AuthCodeField(
            model: control.stringCode,
            count: 6,
            inputType: TextInputType.text,
            itemBuilder: (context, index) => CustomCodeItem(
              char: control.stringCode.code[index],
              fieldFocused: control.stringCode.code.hasFocus,
              itemFocused: control.stringCode.code.isFocused(index),
            ),
          ),
          SizedBox(
            height: 48.0,
          ),
          AuthCodeField(
            model: control.fancyCode,
            count: 6,
            widgetBuilder: (context) => CustomCodeField(
              control: control.fancyCode.code,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCodeField extends StateboundWidget<AuthCodeModel> {
  final count;
  final TextInputType inputType;
  final IndexedWidgetBuilder itemBuilder;
  final WidgetBuilder widgetBuilder;

  AuthCodeField({
    Key key,
    AuthCodeModel model,
    this.count: 4,
    this.inputType: TextInputType.number,
    this.itemBuilder,
    this.widgetBuilder,
  }) : super(key: key, control: model);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          InputCodeField(
            control: control.code,
            count: count,
            inputType: inputType,
            itemBuilder: itemBuilder,
            builder: widgetBuilder,
            decoration: InputCodeDecoration(
              focusColor: Colors.blueGrey,
            ),
          ),
          if (control.message != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(control.message),
            ),
          CaseWidget(
            activeCase: control.loading,
            builders: {
              true: (_) => Container(
                    width: 192.0,
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              false: (_) => Container(
                    width: 192.0,
                    child: RaisedButton(
                      onPressed: control.validate,
                      child: Text('validate'),
                    ),
                  ),
            },
          ),
        ],
      ),
    );
  }
}

class CustomCodeItem extends StatelessWidget {
  final String char;
  final bool fieldFocused;
  final bool itemFocused;

  const CustomCodeItem({
    Key key,
    this.char,
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
        color: fieldFocused
            ? (itemFocused ? Colors.grey : Colors.grey.withOpacity(0.5))
            : Colors.grey.withOpacity(0.25),
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
          color: control.isFocused(i, true)
              ? Colors.greenAccent.withOpacity(0.25)
              : Colors.transparent,
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
          border: Border.all(
              color: control.hasFocus ? Colors.green : Colors.blueGrey),
        ),
        child: Row(
          children: items,
        ),
      ),
    );
  }
}
