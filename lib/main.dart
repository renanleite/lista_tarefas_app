import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _listaTarefas = [];
  final _tarefaController = TextEditingController();
  Map<String, dynamic> _removido;
  int _removidoPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _listaTarefas = json.decode(data);
      });
    });
  }

  Future _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _listaTarefas.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"]) {
          return -1;
        } else
          return 0;
      });

      _saveData();
    });
  }

  void _addTarefa() {
    Navigator.of(context, rootNavigator: true).pop();

    if (_tarefaController.text == "") {
      return;
    }
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa["title"] = _tarefaController.text;
      _tarefaController.text = "";
      novaTarefa["ok"] = false;
      _listaTarefas.add(novaTarefa);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lista de Tarefas",
          style: TextStyle(fontSize: 25, color: Colors.white),
        ),
        backgroundColor: Colors.grey.shade800,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Adicione a tarefa:"),
                  content: TextField(
                    controller: _tarefaController,
                  ),
                  actions: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.deepOrange),
                        onPressed: _addTarefa,
                        child: Text("ADD"))
                  ],
                );
              });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
      ),
      body: Container(
          padding: EdgeInsets.only(top: 5, left: 8, right: 8),
          child: RefreshIndicator(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                        padding: EdgeInsets.only(top: 10),
                        itemCount: _listaTarefas.length,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: UniqueKey(),
                            background: Container(
                              color: Colors.red,
                              child: Align(
                                alignment: Alignment(-0.85, 0),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            direction: DismissDirection.startToEnd,
                            child: Card(
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child: Column(
                                  children: <Widget>[
                                    CheckboxListTile(
                                      title:
                                      Text(_listaTarefas[index]["title"], style: TextStyle(decoration: TextDecoration.none),),

                                      value: _listaTarefas[index]["ok"],
                                      activeColor: Colors.deepOrange,
                                      onChanged: (verdade) {
                                        setState(() {
                                          _listaTarefas[index]["ok"] = verdade;
                                          _saveData();
                                        });
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                            onDismissed: (direction) {
                              setState(() {
                                _removido = Map.from(_listaTarefas[index]);
                                _removidoPos = index;
                                _listaTarefas.removeAt(index);
                                _saveData();
                              });

                              final sna = SnackBar(
                                content: Text(
                                    "Tarefa \"${_removido["title"]}\" removida."),
                                action: SnackBarAction(
                                  label: "Desfazer",
                                  onPressed: () {
                                    setState(() {
                                      _listaTarefas.insert(
                                          _removidoPos, _removido);
                                      _saveData();
                                    });
                                  },
                                ),
                                duration: Duration(seconds: 3),
                              );

                              Scaffold.of(context).showSnackBar(sna);
                            },
                          );
                        }),
                  )
                ],
              ),
              onRefresh: _refresh)),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/notas.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_listaTarefas);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (i) {
      return null;
    }
  }
}
