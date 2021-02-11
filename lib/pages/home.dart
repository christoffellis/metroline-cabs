import 'package:flutter/material.dart';
import 'package:nfc_in_flutter/nfc_in_flutter.dart';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

Future<String> loadCSVDrivers() async {
  return await rootBundle.loadString('assets/drivers.csv');
}

Map countryCode = {
  'US': '+ 1',
};

bool hasWritten = false;

String pageMode = 'listMode';

String nfcData = '';
String writeMessage = '';

String hostURL = 'google.com';

String lastDriver;
int currentDriverIndex = 0;
List<List<dynamic>> csvDrivers = [[]];

bool readyToWriteOne = false;

class _HomeState extends State<Home> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadCSVDrivers().then((value) {
      setState(() {
        csvDrivers = const CsvToListConverter().convert(value);
        csvDrivers.removeAt(0);
      });
    });

    if (lastDriver != null) {
      currentDriverIndex = csvDrivers.indexOf(csvDrivers
          .firstWhere((driver) => driver[1] + driver[2] == lastDriver));
    }

    Stream<NDEFMessage> stream = NFC.readNDEF();

    stream.handleError(() {});

    stream.listen((NDEFMessage message) {
      if (pageMode == 'singles') {
        NDEFMessage newMessage = NDEFMessage.withRecords([
          NDEFRecord.uri(Uri(
            host: hostURL,
          ))
        ]);
        message.tag.write(newMessage);
      } else if (pageMode == 'listMode') {
        NDEFMessage newMessage = NDEFMessage.withRecords([
          NDEFRecord.uri(Uri(
            host: hostURL,
            query:
                'driver=${csvDrivers[currentDriverIndex][1] + csvDrivers[currentDriverIndex][2]}&telNo=${csvDrivers[currentDriverIndex][5]}',
          ))
        ]);
        message.tag.write(newMessage);
        setState(() {
          hasWritten = true;
          Future.delayed(Duration(milliseconds: 1200)).then((value) {
            setState(() {
              csvDrivers.removeAt(currentDriverIndex);
              hasWritten = false;
            });
          });
        });
        lastDriver = csvDrivers[currentDriverIndex][1] +
            csvDrivers[currentDriverIndex][2];
      } else {
        print(message.data);
        setState(() {
          if (message.data != null)
            nfcData = message.data;
          else
            nfcData = 'NFC is empty';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Metroline Driver NFC Writer'),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(24),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pageMode = 'listMode';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.list),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors
                          .lightBlueAccent[pageMode == 'listMode' ? 200 : 100],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pageMode = 'singles';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.person),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors
                          .deepPurpleAccent[pageMode == 'singles' ? 200 : 100],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pageMode = 'test';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.policy),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.redAccent[pageMode == 'test' ? 200 : 100],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            pageMode == 'listMode'
                ? 'All Drivers'
                : pageMode == 'singles'
                    ? 'Write one driver'
                    : 'Test a Sticker',
            style: TextStyle(fontSize: 20),
          ),
          Expanded(
              child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                color: Colors.black.withOpacity(0.05)),
            child: Center(
              child: pageMode == 'listMode'
                  ? Column(children: [
                      Expanded(
                        child: ListView(
                          children: csvDrivers
                              .map((driver) => GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        currentDriverIndex =
                                            csvDrivers.indexOf(driver);
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      margin: EdgeInsets.all(4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.4,
                                            child: Text(
                                              driver[1] + ' ' + driver[2],
                                              style: TextStyle(fontSize: 20),
                                              overflow: TextOverflow.fade,
                                            ),
                                          ),
                                          Text((countryCode[driver[4]] ?? '') +
                                              (driver[5] != null
                                                  ? driver[5].toString()
                                                  : ''))
                                        ],
                                      ),
                                      decoration: BoxDecoration(
                                          color: csvDrivers.indexOf(driver) ==
                                                  currentDriverIndex
                                              ? hasWritten
                                                  ? Colors.lightGreenAccent
                                                      .withOpacity(0.5)
                                                  : Colors.black
                                                      .withOpacity(0.1)
                                              : Colors.black.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      Container(
                        child: Text(
                          'Tap an NFC to write the highlighted Driver',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ])
                  : pageMode == 'singles'
                      ? Column(
                          children: [
                            Text(
                              'Enter driver details below and click write to write their data to the NFC',
                              textAlign: TextAlign.center,
                            ),
                            Container(
                              margin: EdgeInsets.all(8),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.deepPurpleAccent.withOpacity(0.2),
                              ),
                              child: TextFormField(
                                decoration:
                                    InputDecoration(hintText: 'Driver name'),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.all(8),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.deepPurpleAccent.withOpacity(0.2),
                              ),
                              child: TextFormField(
                                decoration:
                                    InputDecoration(hintText: 'Driver number'),
                              ),
                            ),
                            RaisedButton(
                                color: readyToWriteOne
                                    ? Colors.lightGreenAccent[100]
                                    : Colors.redAccent[100],
                                onPressed: () {
                                  setState(() {
                                    readyToWriteOne = !readyToWriteOne;
                                  });
                                },
                                child: Text(
                                    '${readyToWriteOne ? '' : 'Not'} Ready To Write')),
                            Text(writeMessage)
                          ],
                        )
                      : Container(
                          child: Column(
                            children: [
                              const Text(
                                'Now reading NFC stickers. Tap one to view its content',
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: 24,
                              ),
                              Text(nfcData)
                            ],
                          ),
                        ),
            ),
            margin: EdgeInsets.all(36),
          )),
        ],
      ),
    );
  }
}
