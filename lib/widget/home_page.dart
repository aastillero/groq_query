import 'dart:io';
import 'package:flutter/material.dart';
import 'package:groq_proj/services/voice_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/chat_service.dart';
import '../services/image_service.dart';
import '../services/preferences_manager.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _responseText = "";
  String _transcribedText = "";
  String _selectedLanguage = "English";
  String _systemPrompt = "";
  bool _systemSpeechEnabled = false;
  bool _systemDeepThinkEnabled = false;
  String? _imageUrl;

  List<XFile> _capturedImages = []; // List to store captured images
  Map<int, bool> _uploadingStates = {};

  late AudioService auService;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    auService = context.read<AudioService>();
    // Add a listener to the notifier
    auService.isRecordingNotifier.addListener(() async {
      print("<<<<< ${auService.isRecordingNotifier.value}");
      if (!auService.isRecordingNotifier.value) {
        final chatService = context.read<ChatService>();
        //await auService.playRecording();
        chatService.transcibeAudio(auService.getRecordedFilePath());
      }
    });
  }

  Future<void> _initializePreferences() async {
    final preferences = context.read<PreferencesManager>();
    final chatService = context.read<ChatService>();

    _systemPrompt = await preferences.getSystemPrompt() ?? chatService.defaultPrompt;
    _selectedLanguage = await preferences.getSelectedLanguage() ?? "English";
    _systemSpeechEnabled = await preferences.getSystemSpeech() ?? false;
    _systemDeepThinkEnabled = await preferences.getDeepThinking() ?? false;

    setState(() {
      chatService.systemPrompt = _systemPrompt!;
      chatService.selectedLanguage = _selectedLanguage!;
    });
  }

  Future<void> _sendMessage(String message) async {
    print("SEND MESSAGE");
    final chatService = context.read<ChatService>();
    final voiceService = context.read<VoiceService>();

    try {
      print("sending message chatService...");
      final response = await chatService.sendMessage(message);
      setState(() {
        _responseText = response;
        if(_systemSpeechEnabled) {
          voiceService.speak(response);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message")),
      );
    }
  }

  Future<void> _sendImageMessage(String message, String imageUri) async {
    final imageService = context.read<ImageService>();
    final chatService = context.read<ChatService>();

    try {
      final response = await chatService.sendMessageWithImage(message, imageUri);
      setState(() {
        _responseText = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send image message")),
      );
    }
  }

  Future<void> _startMonitoring() async {
    final audioService = context.read<AudioService>();

    try {
      await audioService.startMonitoring();
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to start monitoring")),
      );
    }
  }

  Future<void> _stopMonitoring() async {
    final audioService = context.read<AudioService>();

    try {
      await audioService.stopMonitoring();
      //await audioService.playRecording();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to stop monitoring")),
      );
    }
  }

  Future<void> _captureImage() async {
    final imageService = context.read<ImageService>();

    try {
      //final File? image = await imageService.captureImage();
      final XFile? image = await imageService.captureXFile();
      String? imageUri = await imageService.createImageAndSend(image);
      if (imageUri != null) {
        setState(() {
          _sendImageMessage(_systemPrompt ?? '', imageUri);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture image")),
      );
    }
  }

  Future<void> _showTextInputDialog() async {
    String inputText = "";
    final imageService = context.read<ImageService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the bottom sheet to expand for large content
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            bool isUploading() {
              return _uploadingStates.values.any((state) => state == true);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Attach Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Message/Question', style: TextStyle(fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: () async {
                          final XFile? image = await imageService.captureXFile();
                          if (image != null) {
                            setState(() {
                              _capturedImages.add(image); // Add the image to the list
                              _uploadingStates[_capturedImages.length - 1] = true;
                            });
                            imageService.createImageAndSend(image).then((imgUri){
                              setState((){
                                _imageUrl = imgUri;
                                _uploadingStates[_capturedImages.length - 1] = false;
                              });
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Display thumbnails of captured images
                  if (_capturedImages.isNotEmpty)
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _capturedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.file(
                                  File(_capturedImages[index].path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Remove Icon
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _capturedImages.removeAt(index); // Remove the image
                                      _uploadingStates.remove(index); // Remove the state
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              // Loading Icon
                              if (_uploadingStates[index] == true)
                                Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 10),
                  // Text area
                  TextFormField(
                    onChanged: (value) {
                      inputText = value;
                    },
                    maxLines: 10,
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the bottom sheet
                          _capturedImages.clear(); // Clear the captured images list
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: isUploading() ? null : () {
                          print('User entered: $inputText');
                          print('Captured images: ${_capturedImages.map((img) => img.path).toList()}');
                          if(_capturedImages.isNotEmpty && _imageUrl != null) {
                            _sendImageMessage(inputText, _imageUrl!);
                          } else {
                            _sendMessage(inputText);
                          }
                          Navigator.of(context).pop(); // Close the bottom sheet
                          _capturedImages.clear(); // Clear the captured images list
                        },
                        child: Text('Submit'),
                        style: TextButton.styleFrom(
                          foregroundColor: isUploading() ? Colors.grey : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConfigurationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the bottom sheet to expand fully
      builder: (BuildContext context) {
        String localSelectedLanguage = _selectedLanguage; // Local variable for modal
        String localPromptText = _systemPrompt; // Local variable for modal
        bool localSpeechEnabled = _systemSpeechEnabled;
        bool localDeepThinkEnabled = _systemDeepThinkEnabled;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown for language selection
                  Row(
                    children: [
                      Text('Language:', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 16),
                      DropdownButton<String>(
                        value: localSelectedLanguage,
                        items: ['English', 'Tagalog'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) async {
                          setModalState(() {
                            localSelectedLanguage = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Speech toggle
                  Row(
                    children: [
                      Text('Speech:', style: TextStyle(fontSize: 16)),
                      Spacer(),
                      Switch(
                        value: localSpeechEnabled,
                        onChanged: (bool value) {
                          setModalState(() {
                            localSpeechEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Speech toggle
                  Row(
                    children: [
                      Text('Deep Thinking:', style: TextStyle(fontSize: 16)),
                      Spacer(),
                      Switch(
                        value: localDeepThinkEnabled,
                        onChanged: (bool value) {
                          setModalState(() {
                            localDeepThinkEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // TextFormField for "Prompt"
                  TextFormField(
                    initialValue: _systemPrompt,
                    onChanged: (value) {
                      localPromptText = value;
                    },
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: 'Prompt',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the bottom sheet
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final chatService = context.read<ChatService>();
                          final preferences = context.read<PreferencesManager>();
                          final voiceService = context.read<VoiceService>();

                          // If you need to do anything special when speech is toggled,
                          // this is a good place to handle that logic before saving.
                          // For example:
                          // if (localSpeechEnabled) {
                          //   // TTS or voice input logic
                          // } else {
                          //   // Possibly disable TTS or voice input
                          // }

                          try {
                            // Example for setting speech recognition/TTs language:
                            await voiceService.setLanguage(
                                localSelectedLanguage == "Tagalog" ? "fil-PH" : "en-US"
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Language not supported: $e"),
                              ),
                            );
                          }

                          setState(() {
                            _selectedLanguage = localSelectedLanguage;

                            // Manage the system prompt logic
                            if(_selectedLanguage == "Tagalog") {
                              if(!localPromptText.contains(chatService.tagalogPrompt)) {
                                _systemPrompt = "$localPromptText ${chatService.tagalogPrompt}";
                              }
                            } else {
                              if(localPromptText.contains(chatService.tagalogPrompt)) {
                                localPromptText = localPromptText.replaceAll(chatService.tagalogPrompt, "");
                              }
                              _systemPrompt = localPromptText;
                            }

                            // Store preferences
                            preferences.setSelectedLanguage(_selectedLanguage);
                            preferences.setSystemPrompt(_systemPrompt);

                            // Store the speech toggle state if needed
                            preferences.setSystemSpeech(localSpeechEnabled);

                            print("PROMPT: $_systemPrompt");
                          });

                          Navigator.of(context).pop(); // Close the bottom sheet
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final scrWidth = MediaQuery.of(context).size.width;
    final scrHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 40), // Add some space at the top
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _responseText,
                      style: TextStyle(fontSize: 23, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hidden tappable action in the top-left corner
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: () {
                // Perform your hidden action here
                _showConfigurationSheet(context);
              },
              child: Container(
                width: scrWidth * 0.2, // Adjust width for tappable area
                height: scrHeight * 0.1, // Adjust height for tappable area
                color: Colors.transparent, // Keep it invisible
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showTextInputDialog,
            tooltip: "Send Text",
            child: const Icon(Icons.message_outlined),
          ),
          const SizedBox(width: 10),
          /*FloatingActionButton(
            onPressed: _captureImage,
            tooltip: "Capture Image",
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              _showConfigurationSheet(context);
            },
            tooltip: "Settings",
            child: const Icon(Icons.settings),
          ),
          const SizedBox(width: 10),*/
          FloatingActionButton(
            onPressed: audioService.isMonitoring ? _stopMonitoring : _startMonitoring,
            tooltip: "Mic",
            child: Icon(audioService.isMonitoring ? Icons.mic : Icons.mic_off),
          ),
        ],
      ),
    );
  }
}