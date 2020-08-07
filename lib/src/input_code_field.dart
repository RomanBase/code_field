import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controls [InputCodeField], receives input and handles value changes.
/// Implements [TextInputConnection] and receives all keyboard events.
class InputCodeControl extends ChangeNotifier {
  /// Handles focus of Widget.
  final _focusNode = FocusNode();

  /// Focus node of [InputCodeField]. Used to auto focus and also to ensure visibility when Widget is activated.
  FocusNode get focusNode => _focusNode;

  /// Checks if corresponding [InputCodeField] is focused.
  bool get hasFocus => focusNode.hasFocus;

  /// Text and Action input.
  TextInputConnection _connection;

  /// Next index to fill.
  int _activeIndex = 0;

  /// Returns index of active field - next index to fill.
  int get activeIndex => _activeIndex;

  /// Current text value - an input state.
  TextEditingValue _value = TextEditingValue();

  /// Current text value with correct cursor position.
  TextEditingValue get _valueCursor => _value.copyWith(selection: TextSelection.collapsed(offset: activeIndex));

  /// Returns current text value.
  String get value => _value.text ?? '';

  /// Sets current text value.
  set value(String code) => _updateText(code);

  /// Number of fields.
  int _count = 0;

  /// Returns number of fields - required text length.
  int get count => _count;

  /// Returns number of not empty fields - text length.
  int get filledCount => value.length;

  /// Returns `true` if all fields are filled.
  bool get isFilled => filledCount == count;

  /// Checks if control is ready to use and mounted to Widget.
  bool get isInitialized => count > 0;

  /// Checks if input connection is attached.
  bool get inputActive => _connection?.attached ?? false;

  /// Callback when last field is filled.
  VoidCallback _done;

  /// String regex to filter input. Matching test is applied at whole text value.
  /// So use ^[0-9]*$ to match only numbers.
  String inputRegex;

  /// Obscure input fields.
  bool _obscure;

  /// Checks if input fields are obscured and text should be hidden.
  bool get isObscured => _obscure;

  /// Controls [InputCodeField], receives input from keyboard and handles value editing.
  /// [code] - Initial value.
  /// [inputRegex] - String regex to filter input. Matching test is applied at whole text value.
  InputCodeControl({String code, this.inputRegex}) {
    if (code != null) {
      _value = TextEditingValue(text: code);
      _activeIndex = code.length;
    }
  }

  /// Configures this control based on [InputCodeField] properties.
  void _setCodeConfiguration(int count, bool obscure) {
    _count = count;
    _obscure = obscure;

    if (value.length > _count) {
      _updateText(value);
    }
  }

  /// Returns char at given [index] or empty String.
  String operator [](int index) {
    if (value.length > index) {
      return value[index];
    }

    return '';
  }

  /// Validates input [value] with [inputRegex].
  bool validateInput(String value) {
    if (inputRegex == null) {
      return true;
    }

    return RegExp(inputRegex).hasMatch(value ?? '');
  }

  /// Registers [VoidCallback] that is triggered when last field is filled.
  void done(VoidCallback callback) => _done = callback;

  /// Sets field to be obscured and notifies Widget to hide values.
  void setObscure(bool value) {
    assert(isInitialized);

    if (isObscured == value) {
      return;
    }

    _obscure = value;

    notifyListeners();
  }

  /// Updates [TextEditingValue] with given [text] and sets cursor to correct position.
  /// If input validation fails and connection is assembled, previous value is send to input client.
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

  /// Updates current [TextEditingValue] if [value] is different and notifies Widget.
  /// Also handles [done] callback when all fields are filled.
  void _updateValue(TextEditingValue value) {
    if (_value == value) {
      return;
    }

    if (_value.text == value.text) {
      _value = value;
      return;
    }

    if (value.text.length > _count || !validateInput(value.text)) {
      // Seems like duplicate call, but value can be updated directly by TextInputClient.
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

    notifyListeners();
  }

  /// Executes [done] callback.
  void _onDone() => _done?.call();

  /// Removes focus from [focusNode].
  /// Check [FocusNode.unfocus].
  void unfocus() => focusNode.unfocus();

  /// Requests focus for [focusNode].
  /// Check [FocusNode.requestFocus].
  void focus() => focusNode.requestFocus();

  /// Checks if field at given [index] is focused.
  /// [clamp] - Returned value is clamped between 0 and last possible index - useful to highlight last field when is filled.
  bool isFocused(int index, [bool clamp = false]) {
    return hasFocus && (clamp ? math.min(_activeIndex, count - 1) : _activeIndex) == index;
  }

  /// Clears current text and sets empty [TextEditingValue].
  void clear() => value = null;

  /// Helper function to copy/paste value from System clipboard.
  Future<void> copyFromClipboard() async {
    ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data != null && validateInput(data.text)) {
      value = data.text;
    }
  }

  /// Helper function to copy current value to System clipboard.
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

/// Basic entity to hold decoration of default input look.
/// Used only when [InputCodeField.builder] and [InputCodeField.itemBuilder] is null.
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

/// Code text field - draws separated input fields for each char.
/// State implements [TextInputClient] so [InputCodeControl] can receive all keyboard inputs and actions.
class InputCodeField extends StatefulWidget {
  final InputCodeControl control;
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

  /// [count] number of fields, can't be null or zero.
  /// [spacing] distance between fields.
  /// [itemBuilder] custom field builder - [Row] and spacing is generated, return just one code field. [decoration] is ignored.
  /// [builder] custom widget builder - Full control of Widget, return all code fields. Everything is ignored. Use [] operator on [InputCodeControl] to get [char] for field at given index.
  /// [decoration] use to decorate default field style. Used only when [itemBuilder] and [builder] is null.
  InputCodeField({
    Key key,
    @required this.control,
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
  })  : assert(count != null && count > 0),
        super(key: key);

  @override
  _InputCodeFieldState createState() => _InputCodeFieldState();
}

/// State of [InputCodeField].
class _InputCodeFieldState extends State<InputCodeField> implements TextInputClient {
  InputCodeControl get control => widget.control;

  TextInputConfiguration get _inputConfig => TextInputConfiguration(
        inputType: widget.inputType,
        inputAction: widget.inputAction,
        autocorrect: false,
        enableSuggestions: false,
      );

  @override
  void initState() {
    super.initState();

    control._setCodeConfiguration(widget.count, widget.obscure);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          FocusScope.of(context).autofocus(control.focusNode);
        }
      });
    }

    control.addListener(_notifyState);
  }

  void _notifyState() {
    setState(() {});
  }

  @override
  void didUpdateWidget(InputCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.count != oldWidget.count || widget.obscure != oldWidget.obscure) {
      control._setCodeConfiguration(widget.count, widget.obscure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.enabled) {
          return;
        }

        if (control.focusNode.hasFocus) {
          _handleFocus(true);
        } else {
          FocusScope.of(context).requestFocus(control.focusNode);
        }
      },
      onLongPress: () async {
        if (!widget.enabled) {
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
    return widget.builder == null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: List<Widget>.generate(widget.count, (index) => _buildInput(context, index, control.isFocused(index) && widget.enabled))
                .expand((item) sync* {
                  yield SizedBox(width: widget.spacing);
                  yield item;
                })
                .skip(1)
                .toList(),
          )
        : widget.builder(context);
  }

  Widget _buildInput(BuildContext context, int index, bool hasFocus) {
    final theme = Theme.of(context);
    final decoration = this.widget.decoration ?? InputCodeDecoration();

    return widget.itemBuilder == null
        ? Flexible(
            fit: decoration.width > 0.0 ? FlexFit.loose : FlexFit.tight,
            child: Container(
              constraints: BoxConstraints.expand(width: decoration.width, height: decoration.height),
              decoration: (hasFocus ? decoration.focusedBox : decoration.box) ??
                  BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: (hasFocus ? (decoration.focusColor ?? theme.primaryColorDark) : (widget.enabled ? (decoration.color ?? theme.primaryColor) : (decoration.disableColor ?? theme.disabledColor))).withOpacity(control.hasFocus ? 1.0 : 0.5),
                        width: 2.0,
                      ),
                    ),
                  ),
              child: Center(
                child: Text(
                  (control[index].isNotEmpty && control.isObscured) ? '•' : control[index],
                  style: widget.enabled ? (decoration.textStyle ?? theme.primaryTextTheme.headline3) : (decoration.disableTextStyle ?? theme.primaryTextTheme.headline3.copyWith(color: theme.disabledColor)),
                ),
              ),
            ),
          )
        : widget.itemBuilder(context, index);
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
          alignment: widget.decoration?.focusAlignment ?? 0.0,
        ),
      );
    } else {
      control._connection?.close();
    }

    _notifyState();
  }

  @override
  void performAction(TextInputAction action) => control._onDone();

  @override
  void updateEditingValue(TextEditingValue value) => control._updateValue(value);

  @override
  TextEditingValue get currentTextEditingValue => control._value;

  @override
  void connectionClosed() {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  AutofillScope get currentAutofillScope => null;

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void dispose() {
    super.dispose();

    control.removeListener(_notifyState);
    control.dispose();
  }
}
