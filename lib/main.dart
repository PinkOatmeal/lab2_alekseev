import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Result {
  final String name;
  final bool isCinema;

  Result({required this.name, required this.isCinema});

  factory Result.fromJson(MapEntry<String, int> json) {
    return Result(
      name: json.key,
      isCinema: json.value == 1 ? true : false,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab2',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const LabHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LabHomePage extends StatefulWidget {
  const LabHomePage({Key? key}) : super(key: key);

  final String serverUri = "http://192.168.99.100:8000";

  @override
  State<LabHomePage> createState() => _LabHomePageState();
}

class _LabHomePageState extends State<LabHomePage> {
  List<String>? pupils;
  String? pupil;
  int? isCinema;
  List<Result>? _result;

  Future<List<String>> _getPupils() async {
    final uri = Uri.parse("${widget.serverUri}/names");
    final response = await http.get(uri);
    return await jsonDecode(response.body).cast<String>();
  }

  Future<List<Result>> _getResult(String name, int isCinema) async {
    final uri = Uri.parse("${widget.serverUri}/is_cinema");
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(
          <String, String>{"name": name, "is_cinema": isCinema.toString()}),
    );
    final Map<String, int> results =
        json.decode(response.body)["result"].cast<String, int>();
    return results.entries.map((e) => Result.fromJson(e)).toList();
  }

  @override
  void initState() {
    super.initState();
    _getPupils().then((value) {
      pupils = value;
      pupil = pupils![0];
      isCinema = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pupils != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropDown(
                      values: pupils!,
                      onValueChosen: (val) => setState(() {
                        pupil = val;
                      }),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: const Text("Идет в кино?"),
                    ),
                    DropDown(
                      values: const ["Да", "Нет"],
                      onValueChosen: (String val) => setState(() {
                        isCinema = val == "Да" ? 1 : 0;
                      }),
                    )
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await _getResult(pupil!, isCinema!);
                    setState(() {
                      _result = result;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 32.0,
                    ),
                    child: const Text("Отправить"),
                  ),
                ),
                _result == null
                    ? const SizedBox.shrink()
                    : Column(
                        children: List.generate(
                          _result!.length,
                          (i) => Container(
                            margin: const EdgeInsets.all(4.0),
                            child: Text("${_result![i].name} "
                                "${_result![i].isCinema ? "идет" : "не идет"} в кино"),
                          ),
                        ),
                      ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class DropDown extends StatefulWidget {
  const DropDown({Key? key, required this.values, required this.onValueChosen})
      : super(key: key);

  final List<String> values;
  final void Function(String val) onValueChosen;

  @override
  State<DropDown> createState() => _DropDownState();
}

class _DropDownState extends State<DropDown> {
  late String value;

  @override
  void initState() {
    super.initState();
    value = widget.values.first;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      items: widget.values
          .map((e) => DropdownMenuItem(
              value: e,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0,
                ),
                child: Text(e),
              )))
          .toList(),
      onChanged: (String? newValue) => setState(() {
        value = newValue!;
        widget.onValueChosen(newValue);
      }),
    );
  }
}
