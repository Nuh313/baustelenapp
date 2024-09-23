import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// Hauptklasse des Kalenders
class Kalender extends StatefulWidget {
  @override
  _KalenderState createState() => _KalenderState();
}

class _KalenderState extends State<Kalender> {
  // Liste der ausgewählten Ereignisse für den gewählten Tag
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;
  
  // Der aktuell ausgewählte Tag
  DateTime? _selectedDay;
  
  // Map, die alle Ereignisse (Tasks) nach Datum speichert
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    // Initialisiert den ValueNotifier für die ausgewählten Ereignisse
    _selectedEvents = ValueNotifier([]);
  }

  @override
  void dispose() {
    // Wert wird freigegeben, wenn das Widget entfernt wird
    _selectedEvents.dispose();
    super.dispose();
  }

  // Diese Methode wird aufgerufen, wenn ein Tag im Kalender ausgewählt wird
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _updateSelectedEvents(); // Aktualisiert die Liste der Ereignisse für den gewählten Tag
      });
    }
  }

  // Dialog zum Hinzufügen oder Bearbeiten einer Aufgabe (Task)
  void _showTaskDialog({String? existingTask, String? existingPriority, String? existingTime}) {
    final TextEditingController taskController = TextEditingController(text: existingTask);
    final TextEditingController timeController = TextEditingController(text: existingTime);
    
    // Standardmäßig ist die Priorität "Mittelschwer", es sei denn, eine andere wird bearbeitet
    String? selectedPriority = existingPriority ?? 'Mittelschwer';

    // Dialog zur Eingabe einer neuen oder zum Bearbeiten einer bestehenden Aufgabe
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingTask == null ? 'Neue Aufgabe hinzufügen' : 'Aufgabe bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Eingabefeld für den Aufgabentext
              TextField(
                controller: taskController,
                decoration: InputDecoration(hintText: 'Aufgabentext eingeben'),
              ),
              SizedBox(height: 10),
              // Eingabefeld für die Zeit der Aufgabe
              TextField(
                controller: timeController,
                decoration: InputDecoration(hintText: 'Zeit eingeben (z.B. 14:00)'),
              ),
              SizedBox(height: 10),
              // Dropdown zur Auswahl der Priorität der Aufgabe
              DropdownButton<String>(
                value: selectedPriority,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPriority = newValue;
                  });
                },
                items: <String>['Leicht', 'Mittelschwer', 'Schwer']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            // Button zum Speichern oder Hinzufügen der Aufgabe
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty && _selectedDay != null) {
                  final newTask = {
                    'text': taskController.text,
                    'time': timeController.text,
                    'priority': selectedPriority,
                  };

                  setState(() {
                    // Wenn es sich um eine neue Aufgabe handelt
                    if (existingTask == null) {
                      if (_events[_selectedDay] == null) {
                        _events[_selectedDay!] = [];
                      }
                      _events[_selectedDay]!.add(newTask);
                    } else {
                      // Wenn es sich um das Bearbeiten einer vorhandenen Aufgabe handelt
                      final taskIndex = _events[_selectedDay]!.indexWhere((task) => task['text'] == existingTask);
                      if (taskIndex != -1) {
                        _events[_selectedDay]![taskIndex] = newTask;
                      }
                    }
                    _updateSelectedEvents(); // Aktualisiert die Ereignisliste
                  });
                }
                Navigator.of(context).pop(); // Schließt den Dialog
              },
              child: Text(existingTask == null ? 'Hinzufügen' : 'Speichern'),
            ),
            // Button zum Abbrechen und Schließen des Dialogs
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  // Aktualisiert die Liste der Aufgaben für den ausgewählten Tag
  void _updateSelectedEvents() {
    _selectedEvents.value = _events[_selectedDay] ?? [];
  }

  // Gibt die Farbe des Markers basierend auf der höchsten Priorität der Aufgaben zurück
  Color _getMarkerColor(List<Map<String, dynamic>> events) {
    if (events.any((event) => event['priority'] == 'Schwer')) {
      return Colors.red; // Rot für "Schwer"
    } else if (events.any((event) => event['priority'] == 'Mittelschwer')) {
      return Colors.orange; // Orange für "Mittelschwer"
    } else if (events.any((event) => event['priority'] == 'Leicht')) {
      return Colors.green; // Grün für "Leicht"
    }
    return Colors.grey; // Standardfarbe Grau
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kalender')),
      body: Column(
        children: [
          // Der Kalender-Container
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  offset: Offset(0, 5), // Schattenposition
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: (day) {
                return _events[day]?.map((event) => '${event['text']} (${event['priority']})')?.toList() ?? [];
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              // Hier werden die Marker (Punkte) für Tage mit Aufgaben gezeichnet
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (_events[day] != null && _events[day]!.isNotEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        color: _getMarkerColor(_events[day]!),
                        shape: BoxShape.circle,
                      ),
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    );
                  }
                  return null;
                },
                defaultBuilder: (context, date, _) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSameDay(date, _selectedDay) ? Colors.blueAccent : Colors.transparent,
                    ),
                    child: Center(child: Text('${date.day}')),
                  );
                },
              ),
            ),
          ),
          if (_selectedDay == null)
            Center(
              child: Text(
                'Bitte wählen Sie ein Datum aus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
          // Anzeige der Aufgaben des ausgewählten Tages
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _selectedEvents,
            builder: (context, tasks, _) {
              return Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Anzeige des Aufgabentexts und der Priorität
                          Text(
                            '${task['text']} (${task['priority']})',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                            ),
                          ),
                          SizedBox(height: 4), // Abstand zur Zeit
                          // Anzeige der Zeit, wann die Aufgabe erledigt sein soll
                          Text(
                            'Fällig: ${task['time']}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          // Bearbeiten- und Löschen-Buttons für die Aufgabe
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showTaskDialog(
                                    existingTask: task['text'],
                                    existingPriority: task['priority'],
                                    existingTime: task['time'],
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _events[_selectedDay]?.remove(task); // Aufgabe löschen
                                    _updateSelectedEvents();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      // Floating Action Button zum Hinzufügen einer neuen Aufgabe, wenn ein Datum ausgewählt ist
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
              onPressed: () {
                _showTaskDialog(); // Öffnet Dialog für neue Aufgabe
              },
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: Colors.redAccent, // FAB-Farbe auf Rot geändert
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50), // Runde Form für FAB
              ),
              tooltip: 'Neue Aufgabe hinzufügen',
            )
          : null, // Nur anzeigen, wenn ein Datum ausgewählt wurde
    );
  }
}
