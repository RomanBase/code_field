import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_control/core.dart';

class InputCodeControl extends BaseModel with StateControl {
  final key = GlobalKey();

  final focusNode = FocusNode();

  bool get hasFocus => focusNode.hasFocus;

  TextInputConnection _connection;

  int _activeIndex = 0;

  int get activeIndex => _activeIndex;

  TextEditingValue _value = TextEditingValue();

  TextEditingValue get _valueCursor => _value.copyWith(selection: TextSelection.collapsed(offset: activeIndex));

  String get value => _value.text ?? '';

  set value(String code) => _updateText(code);

  int _count = 0;

  int get count => _count;

  bool get isInitialized => _count > 0;

  bool get isFilled => value.length == _count;

  bool get inputActive => _connection?.attached ?? false;

  VoidCallback _done;

  String inputRegex;

  bool _obscure;

  bool get isObscured => _obscure;

  /// [code] - initial text
  /// [inputRegex] - regex just for input, not for final validation. Use [isFilled] to check if full code is inserted.
  /// For example use ^[0-9]*$ to match only numbers. Regex is also used for text copied from Clipboard.
  InputCodeControl({String code, this.inputRegex}) {
    if (code != null) {
      _value = TextEditingValue(text: code);
      _activeIndex = code.length;
    }
  }

  String operator [](int index) {
    if (value.length > index) {
      return value[index];
    }

    return '';
  }

  bool validateInput(String value) {
    if (inputRegex == null) {
      return true;
    }

    return RegExp(inputRegex).hasMatch(value ?? '');
  }

  void done(VoidCallback callback) => _done = callback;

  void setObscure(bool value) {
    if (isObscured == value) {
      return;
    }

    _obscure = value;

    notifyState();
  }

  void _setCodeConfiguration(int count, bool obscure) {
    _count = count;
    _obscure = obscure;

    if (value.length > _count) {
      _updateText(value);
    }
  }

  void _updateText(String text) {
    if (text == null) {
      _updateValue(TextEditingValue());
    } else {
      if (isInitialized && text.length > _count) {
        text = text.substring(0, _count);
      }

      _updateValue(TextEditingValue(text: text));
    }

    if (inputActive) {
      _connection?.setEditingState(_valueCursor);
    }
  }

  void _updateValue(TextEditingValue value) {
    if (_value == value) {
      return;
    }

    if (value.text.length > _count || !validateInput(value.text)) {
      if (inputActive) {
        _connection?.setEditingState(_valueCursor);
      }

      return;
    }

    _value = value;

    _activeIndex = value.text.length;

    if (isInitialized && activeIndex == _count) {
      _onDone();
    }

    notifyState();
  }

  void _onDone() {
    if (_done != null) {
      _done();
    }
  }

  void unfocus() => focusNode.unfocus();

  void focus() => focusNode.requestFocus();

  bool isFocused(int index, [bool clamp = false]) {
    return hasFocus && (clamp ? math.min(_activeIndex, count - 1) : _activeIndex) == index;
  }

  void clear() => value = null;

  Future<void> copyFromClipboard() async {
    ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data != null && validateInput(data.text)) {
      value = data.text;
    }
  }

  Future<void> copyToClipboard() {
    return Clipboard.setData(ClipboardData(text: value));
  }

  @override
  void dispose() {
    super.dispose();

    _connection?.close();
    _connection = null;

    focusNode.dispose();
  }
}

class InputCodeDecoration {
  final Color color;
  final Color focusColor;
  final TextStyle textStyle;
  final Color disableColor;
  final TextStyle disableTextStyle;
  final BoxDecoration box;
  final BoxDecoration focusedBox;
  final double width;
  final double height;
  final double focusAlignment;

  const InputCodeDecoration({
    this.color,
    this.focusColor,
    this.textStyle,
    this.disableColor,
    this.disableTextStyle,
    this.box,
    this.focusedBox,
    this.width: 0.0,
    this.height: 56.0,
    this.focusAlignment: -16.0,
  });
}

class InputCodeField extends StateboundWidget<InputCodeControl> with OnLayout, ThemeProvider implements TextInputClient {
  final int count;
  final double spacing;
  final bool autofocus;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final IndexedWidgetBuilder itemBuilder;
  final WidgetBuilder builder;
  final InputCodeDecoration decoration;
  final bool enabled;
  final bool obscure;

  /// [count] number of fields, can't be null.
  /// [spacing] distance between fields.
  /// [itemBuilder] custom field builder - [Row] and spacing is generated, return just one code field. [decoration] is ignored.
  /// [builder] custom widget builder - Full control of Widget, return all code fields. Everything is ignored. Use [] operator on [InputCodeControl] or [InputCodeField] to get [char] for field at given index.
  /// [decoration] use to decorate default field style. Used only when [itemBuilder] and [builder] is null.
  InputCodeField({
    @required InputCodeControl control,
    this.count: 6,
    this.spacing: 8.0,
    this.autofocus: false,
    this.inputType: TextInputType.number,
    this.inputAction: TextInputAction.done,
    this.itemBuilder,
    this.builder,
    this.decoration,
    this.enabled: true,
    this.obscure: false,
  })  : assert(count > 0),
        super(key: control.key, control: control);

  TextInputConfiguration get _inputConfig => TextInputConfiguration(
        inputType: inputType,
        inputAction: inputAction,
        autocorrect: false,
        enableSuggestions: false,
      );

  @override
  void onInit(Map args) {
    super.onInit(args);

    control._setCodeConfiguration(count, obscure);
  }

  @override
  void onLayout() {
    if (autofocus && holder.state.mounted) {
      FocusScope.of(context).autofocus(control.focusNode);
    }
  }

  @override
  bool shouldUpdate(CoreWidget oldWidget) {
    final old = oldWidget as InputCodeField;

    if (count != old.count || obscure != old.obscure) {
      control._setCodeConfiguration(count, obscure);
    }

    return super.shouldUpdate(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!enabled) {
          return;
        }

        if (control.focusNode.hasFocus) {
          _handleFocus(true);
        } else {
          FocusScope.of(context).requestFocus(control.focusNode);
        }
      },
      onLongPress: () async {
        if (!enabled) {
          return;
        }

        control.copyFromClipboard();
      },
      child: Focus(
        focusNode: control.focusNode,
        onFocusChange: _handleFocus,
        child: _buildWidget(context),
      ),
    );
  }

  Widget _buildWidget(BuildContext context) {
    return builder == null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: List<Widget>.generate(count, (index) => _buildInput(context, index, control.isFocused(index) && enabled))
                .expand((item) sync* {
                  yield SizedBox(width: spacing);
                  yield item;
                })
                .skip(1)
                .toList(),
          )
        : builder(context);
  }

  Widget _buildInput(BuildContext context, int index, bool hasFocus) {
    final decoration = this.decoration ?? InputCodeDecoration();

    return itemBuilder == null
        ? Flexible(
            fit: decoration.width > 0.0 ? FlexFit.loose : FlexFit.tight,
            child: Container(
              constraints: BoxConstraints.expand(width: decoration.width, height: decoration.height),
              decoration: (hasFocus ? decoration.focusedBox : decoration.box) ??
                  BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: (hasFocus ? (decoration.focusColor ?? theme.primaryColorDark) : (enabled ? (decoration.color ?? theme.primaryColor) : (decoration.disableColor ?? theme.data.disabledColor))).withOpacity(control.hasFocus ? 1.0 : 0.5),
                        width: 2.0,
                      ),
                    ),
                  ),
              child: Center(
                child: Text(
                  (control[index].isNotEmpty && control.isObscured) ? '•' : control[index],
                  style: enabled ? (decoration.textStyle ?? fontPrimary.headline3) : (decoration.disableTextStyle ?? fontPrimary.headline3.copyWith(color: theme.data.disabledColor)),
                ),
              ),
            ),
          )
        : itemBuilder(context, index);
  }

  void _handleFocus(bool hasFocus) {
    if (hasFocus) {
      if (control._connection == null || !control._connection.attached) {
        control._connection = TextInput.attach(this, _inputConfig);
        control._connection.setEditingState(control._valueCursor);
      }

      control._connection.show();

      Future.delayed(
        Duration(milliseconds: 150), // wait for keyboard
        () => Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 300),
          alignment: decoration?.focusAlignment ?? 0.0,
        ),
      );
    } else {
      control._connection?.close();
    }

    control.notifyState();
  }

  @override
  void performAction(TextInputAction action) => control._onDone();

  @override
  void updateEditingValue(TextEditingValue value) => control._updateValue(value);

  @override
  TextEditingValue get currentTextEditingValue => control._value;

/* currently only in master branche
  // unused
  @override
  AutofillScope get currentAutofillScope => null;

  // unused
  @override
  void showAutocorrectionPromptRect(int start, int end) {}
*/
  // unused
  @override
  void connectionClosed() {}

  // unused
  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}
}
