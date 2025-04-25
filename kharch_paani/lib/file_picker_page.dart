import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http; // Import the http package.
import 'dart:convert'; // For JSON decoding.
import 'package:http_parser/http_parser.dart';

class FilePickerPage extends StatefulWidget {
  @override
  State<FilePickerPage> createState() => _FilePickerPageState();
}

class _FilePickerPageState extends State<FilePickerPage> {
  String? _fileName; // Variable to store the selected file name.
  String? _filePath; // Variable to store the selected file path.
  PlatformFile? _file; // Variable to store the selected file bytes.
  bool _showTransformButton = false;

  // Dropdown state variables
  String? _monthCode;
  String? _yearValue;
  String? _bankAccName;

  bool get _isTransformButtonEnabled =>
      _monthCode != null && _yearValue != null && _bankAccName != null;

  Future<void> _pickFile() async {
    // Use the file_picker package to select a file.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'tsv'],
    );

    if (result != null) {
      setFileSelected(result);
    } else {
      // User canceled the picker.
      resetPicker();
    }
  }

  Future<void> _callApi(BuildContext context) async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected to transform!')),
      );
      return;
    }

    // Declare a variable to endpoint the API URL.
    var host = 'https://expense-manager-api-s5zz.onrender.com';
    //var host = 'http://127.0.0.1:8000'; // Localhost for testing.
    try {
      final url = Uri.parse('$host/transform/'); // API endpoint.
      // Create a multipart request.
      // You can also use the file path if you want to send the file directly from the path.
      var request = http.MultipartRequest("POST", url);
      request.fields['account_name'] = _bankAccName!;
      request.fields['month'] = _monthCode!;
      request.fields['year'] = _yearValue!;
      // Add the file to the request.
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _file!.bytes!, // Use the file bytes.
        filename: _fileName, // Use the file name.
        contentType: MediaType('octet-stream', 'tsv'), // Set the content type.
      ));
      // Send the request and get the response.
      var response = await request.send();
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}'); // Print response headers.
      if (response.statusCode == 200) {
        String responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData); // Parse JSON response.
        String message = jsonResponse['message']; // Extract the 'message' key.
        // Handle the response data as needed.
        // Show success ribbon
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green, // Success ribbon background color.
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 50),
                    SizedBox(height: 10),
                    Text(
                      'Success!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      message,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog.
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to transform the file.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _selectMonthAndYear(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      // set last month and year as default date.
      //initialDate: DateTime.now(),
      initialDate: DateTime(DateTime.now().year, DateTime.now().month - 1),
      firstDate: DateTime(2000), // Earliest selectable date.
      lastDate: DateTime(2100), // Latest selectable date.
      initialDatePickerMode: DatePickerMode.year, // Start with year selection.
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // Header background color.
              onPrimary: Colors.white, // Header text color.
              onSurface: Colors.black, // Body text color.
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _monthCode = _getMonthCode(selectedDate.month); // Update month.
        _yearValue = selectedDate.year.toString(); // Update year.
      });
    }
  }

  String _getMonthCode(int month) {
    const monthCodes = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return monthCodes[month - 1];
  }

  void resetPicker() {
    setState(() {
      _fileName = null;
      _filePath = null; // Reset the file path.
      _file = null; // Reset the file bytes.
      _showTransformButton = false;
      _monthCode = null;
      _yearValue = null;
      _bankAccName = null;
    });
  }

  void setFileSelected(FilePickerResult result) async {
    setState(() {
      _fileName = result.files.first.name; // Get the file name.
      _filePath = result.files.first.path; // Get the file path.
      _file = result.files.first; // Get the file bytes.
      _showTransformButton = true; // Show the transform button.
    });
    print('Selected file: $_fileName, Path: $_filePath');
    print('File size: ${_file!.size} bytes'); // Print the file size.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hisaab Kitaab'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.analytics_outlined),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            if (_fileName != null)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width *
                        0.10), // Adjust padding as needed.
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file), // Leading icon.
                    SizedBox(width: 10), // Space between icon and text.
                    Flexible(child: Text('Selected File:')),
                    SizedBox(width: 10), // Space between text and file name.
                    Row(
                      children: [
                        Text(
                          _fileName!,
                          overflow:
                              TextOverflow.ellipsis, // Handle long file names.
                          style: TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            resetPicker();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Center(
                child: ListTile(
                  leading: Icon(Icons.warning),
                  title: Text('No file selected.'),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.20),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _pickFile();
              },
              icon: Icon(Icons.file_upload), // Add an icon here.
              label: Text('Select File'), // Add a label here.
            ),
            SizedBox(height: 40),
            if (_showTransformButton == true)
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: DropdownButton<String>(
                          value: _bankAccName,
                          hint: Text('Select bank account type'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _bankAccName = newValue;
                            });
                          },
                          items: <String>[
                            'Macquarie Transaction account',
                            'Macquarie Credit Card',
                            'CBA Transaction account',
                            'Step Pay account',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          isExpanded: true,
                        ),
                      ),
                      // Add calendar widget here.
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _selectMonthAndYear(context);
                          },
                          icon: Icon(Icons.calendar_today),
                          label: Text(
                            _monthCode != null && _yearValue != null
                                ? '$_monthCode $_yearValue'
                                : 'Select Month & Year',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                  ElevatedButton.icon(
                    onPressed: _isTransformButtonEnabled
                        ? () {
                            _callApi(context);
                          }
                        : null, // Disable button if dropdowns are not selected.
                    icon: Icon(Icons.currency_exchange),
                    label: Text('Transform'),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _pickFile();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
