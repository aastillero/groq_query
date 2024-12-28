import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:groq_proj/services/audio_service.dart';
import 'package:groq_proj/services/chat_service.dart';
import 'package:groq_proj/services/image_service.dart';
import 'package:groq_proj/services/preferences_manager.dart';
import 'package:groq_proj/services/voice_service.dart';
import 'package:groq_proj/util/cloudinary.dart';
import 'package:groq_sdk/groq_sdk.dart';
import 'package:groq_sdk/models/groq_chat.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'util/preferences.dart';
import 'widget/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    /*return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );*/

    return MultiProvider(
      providers: [
        Provider(create: (_) => PreferencesManager()),
        Provider(create: (_) => ImageService()),
        ChangeNotifierProvider(
          create: (_) => AudioService()..initialize(),
        ),
        Provider(create: (_) => ChatService()..initialize()),
        Provider(create: (_) => VoiceService()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

/*class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String jobDesc = "Senior Java Developer";
  final String answerType = "technical interview"; // screening exam
  final String defPrompt = "You are a highly intelligent and friendly AI assistant. Your primary task is to provide thoughtful, helpful, and accurate responses to any message the user sends. Your goal is to make the user feel comfortable and understood, as if they’re talking to a knowledgeable and approachable friend.";
  String systemPrompt = "";
  String _selectedLanguage = "English";
  final String _tagalogPrompt = "Use a natural, conversational tone that reflects how locals in the Philippines typically speak—mixing Tagalog with English as needed. Avoid deep or overly formal Tagalog words unless absolutely necessary.";
  final Groq groq = Groq('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');
  GroqChat? chat;
  GroqChat? chat_vision;
  String _resText = "";

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isMonitoring = false;
  String? _filePath;
  Timer? _silenceTimer;
  final double _silenceThreshold = -45.0; // Decibel threshold for silence
  final Duration _silenceDuration = Duration(seconds: 1); // Silence timeout
  String _transcribedText = "";
  StreamSubscription? _recorderSubscription;
  double _decibelThreshold = 45.0;
  String? imgUri;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _capturedImages = []; // List to store captured images
  Map<int, bool> _uploadingStates = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeRecorder();
    _initializePlayer();
    _setOrientation();
    Preferences.getSharedValue("sysPrompt").then((val){
      setState(() {
        if(val != null) {
          systemPrompt = val;
        } else {
          systemPrompt = defPrompt;
        }
      });
    });
    Preferences.getSharedValue("selectedLang").then((val){
      setState(() {
        if(val != null) {
          _selectedLanguage = val;
        }
      });
    });
    setState(() {
      //systemPrompt = "You are a $jobDesc answering a ${answerType}. Answer as briefly as possible and include code examples if applicable. If its a code problem, write the code only.";
      //systemPrompt = "You are a highly intelligent and friendly AI assistant. Your primary task is to provide thoughtful, helpful, and accurate responses to any message the user sends. Your tone is approachable and engaging, ensuring that the user feels comfortable and understood. Maintain professionalism and warmth in your communication at all times.";
      createChat();
      createChatVision();
    });
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();

    if (!await Permission.microphone.isGranted) {
      throw Exception("Microphone not granted.");
    }

    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(Duration(milliseconds: 100));
  }

  Future<void> _initializePlayer() async {
    await _player.openPlayer();
  }

  void _startSilenceTimer() {
    //print("-------------------- Silence timer started");
    if (_silenceTimer != null && _silenceTimer!.isActive) {
      // Timer is already running
      return;
    }

    _silenceTimer = Timer(_silenceDuration, () {
      //print("-------------------- Stopping recording");
      _stopRecording();
    });

    //print('Silence timer started');
  }

  void _cancelSilenceTimer() {
    //print("-------------------- Silence timer cancelled");
    if (_silenceTimer != null && _silenceTimer!.isActive) {
      _silenceTimer!.cancel();
      _silenceTimer = null;
      //print('Silence timer canceled');
    }
  }

  void startMonitoring() {
    //print("-------------------- START MONITORING");
    setState(() {
      _isMonitoring = true;
    });
    _recorderSubscription = _recorder.onProgress!.listen((event) {
      double currentDb = event.decibels ?? 0.0;
      //print("current Db: [[[[[[${currentDb}]]]]]]");
      if (_isRecording) {
        // If recording, check for silence to potentially stop recording
        if (currentDb < _decibelThreshold) {
          _startSilenceTimer();
        } else {
          _cancelSilenceTimer();
        }
      } else {
        // If not recording, check for speech to start recording
        if (currentDb > _decibelThreshold) {
          _startRecording();
        }
      }
    });

    // Start monitoring with low-level recording
    _recorder.startRecorder(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100,
    );
  }

  void stopMonitoring() async {
    //print("-------------------- STOP MONITORING");
    _cancelSilenceTimer();

    if (_isRecording) {
      await _stopRecording();
    }

    await _recorder.stopRecorder();
    _recorderSubscription?.cancel();
    _recorderSubscription = null;

    setState(() {
      _isMonitoring = false;
    });
  }

  void _startRecording() async {
    //print("-------------------- START RECORDING");
    //if (!_recorder.isRecording) {
      await _recorder.stopRecorder();
      String dir = (await getApplicationDocumentsDirectory()).path;
      _filePath = "${dir}/audio_recording.mp4";

      await _recorder.startRecorder(
        toFile: _filePath,
        codec: Codec.aacMP4,
      );

      setState(() {
        _isRecording = true;
      });
    //}
  }

  Future _stopRecording() async {
    //print("-------------------- STOP RECORDING");
    //if (_recorder.isRecording) {
      await _recorder.stopRecorder();

      // Restart monitoring if still active
      if (_isMonitoring) {
        _recorder.startRecorder(
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 44100,
        );
      }

      setState(() {
        _isRecording = false;
      });

      if (_filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Recording saved to $_filePath")),
        );
        //_playRecording();
        translate().then((val){
          // send to Groq
          // sendMessage();
        });
      }
    //}
  }

  void _playRecording() async {
    if(_filePath != null) {
      if (_isPlaying || !File(_filePath!).existsSync()) {
        return;
      }

      await _player.startPlayer(
        fromURI: _filePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );

      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future sendImageToCloud(File imgF) async {
    //final img = await CloudinaryApi.uploadImageAsset('assets/prob.png');
    final img = await CloudinaryApi.uploadImageFile(imgF);
    setState(() {
      imgUri = img;
    });
  }

  Future<void> _captureAndSaveImage() async {
    try {
      final XFile? capturedImage =
      await _picker.pickImage(source: ImageSource.camera);

      if (capturedImage != null) {
        // Get the application's documents directory
        final Directory appDir = await getApplicationDocumentsDirectory();

        // Create a unique file name based on the current timestamp
        final String fileName = 'prob.png';

        // Copy the file to the app directory
        final File savedImage = await File(capturedImage.path)
            .copy('${appDir.path}/$fileName');

        setState(() {
          _image = savedImage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved at ${savedImage.path}')),
        );
        print("IMAGE: $_image");
        if(_image != null) {
          await sendImageToCloud(_image!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image uploaded at ${imgUri}')),
          );
          setState(() {
            _transcribedText = "Provide an answer to this";
            sendMessage();
          });
        }
      } else {
        print('No image captured.');
      }
    } catch (e) {
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image.')),
      );
    }
  }

  Future createFileImg(XFile? _xfile) async {
    if (_xfile != null) {
      // Get the application's documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();

      // Create a unique file name based on the current timestamp
      final String fileName = 'prob.png';

      // Copy the file to the app directory
      final File savedImage = await File(_xfile.path)
          .copy('${appDir.path}/$fileName');

      setState(() {
        _image = savedImage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved at ${savedImage.path}')),
      );
      if(_image != null) {
        await sendImageToCloud(_image!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded at ${imgUri}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    // Reset orientation on dispose
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> createChat() async {
    //Start a chat with default settings
    if(!await groq.canUseModel(GroqModels.llama_33_70b_versatile)) return;
    chat = groq.startNewChat(GroqModels.llama_33_70b_versatile);
    startLLMStream(chat);
  }

  Future<void> createChatVision() async {
    //Start a chat with default settings
    if(!await groq.canUseModel(GroqModels.llama_32_90b_vision_preview)) return;
    chat_vision = groq.startNewChat(GroqModels.llama_32_90b_vision_preview);
    startLLMStream(chat_vision);
  }

  void startLLMStream(GroqChat? _c) {
    if(_c != null) {
      _c.stream.listen((event) {
        event.when(request: (requestEvent) {
          //Listen for user prompts
          print('Request sent...');
          print(requestEvent.message.content);
        }, response: (responseEvent) {
          //Listen for llm responses
          //print('Received response: ${responseEvent.response.choices.first.message}');
          rateLimit();
        });
      });
    }
  }

  void rateLimit() {
    final rateLimitInfo = chat?.rateLimitInfo;
    print("******************************");
    print("remaining requests: ${rateLimitInfo?.remainingRequestsToday}");
    print("remaining tokens: ${rateLimitInfo?.remainingTokensThisMinute}");
    print("******************************");
  }

  void sendMessage() async {
    if(_transcribedText.isEmpty || chat == null) {
      return;
    }

    if(imgUri != null && imgUri!.isNotEmpty) {
      //print("SELECTED: $_selectedLanguage");
      final (response, usage) = await chat_vision!.sendMessageWithVision(
          //systemPrompt: systemPrompt,
          "Check the image and answer the question: $_transcribedText${(_selectedLanguage == "Tagalog") ? ' $_tagalogPrompt' : ''}",
          imgUri!
      );
      print("In sendMessage: ${response.choices.first.message}");
      setState(() {
        _resText = response.choices.first.message;
      });
    } else {
      final (response, usage) = await chat!.sendMessage(
        systemPrompt: systemPrompt,
        _transcribedText,
      );
      print("In sendMessage: ${response.choices.first.message}");
      setState(() {
        _resText = response.choices.first.message;
      });
    }
  }

  Future transcribe() async {
    if(_filePath != null && _filePath!.isNotEmpty) {
      try {
        final (transcriptionResult, rateLimitInformation) = await groq.transcribeAudio(
            audioFileUrl: _filePath!,
            modelId: GroqModels.whisper_large_v2_turbo
        );
        print("TRANSCRIBED TEXT: ${transcriptionResult.text}"); // The transcribed text
        setState(() {
          _transcribedText = transcriptionResult.text;
        });
      } on GroqException catch (e) {
        print('Error transcribing audio: $e');
      }
    }
  }

  Future translate() async {
    if(_filePath != null && _filePath!.isNotEmpty) {
      try {
        final (transcriptionResult, rateLimitInformation) = await groq.translateAudio(
            audioFileUrl: _filePath!,
            modelId: GroqModels.whisper_large_v3
        );
        print("TRANSLATED TEXT: ${transcriptionResult.text}"); // The transcribed text
        setState(() {
          _transcribedText = transcriptionResult.text;
        });
      } on GroqException catch (e) {
        print('Error translating audio: $e');
      }
    }
  }

  void _incrementCounter() {
    //sendImageToCloud().then((val){
      //_transcribedText = "You are a Senior Java Developer answering a screening exam. Provide an answer to this";
      sendMessage();
    //});
  }

  // Function to show the text input dialog
  void _showTextInputDialog(BuildContext context) {
    String inputText = ""; // To store user input temporarily

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
                          final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                          if (image != null) {
                            setState(() {
                              _capturedImages.add(image); // Add the image to the list
                              _uploadingStates[_capturedImages.length - 1] = true;
                            });
                            createFileImg(image).then((val){
                              setState((){
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
                          //print('User entered: $inputText');
                          //print('Captured images: ${_capturedImages.map((img) => img.path).toList()}');
                          setState(() {
                            _transcribedText = inputText;
                            sendMessage();
                          });
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
        String localPromptText = defPrompt; // Local variable for modal

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
                        onChanged: (newValue) {
                          setModalState(() {
                            localSelectedLanguage = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // TextFormField for "Prompt"
                  TextFormField(
                    initialValue: systemPrompt,
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
                        onPressed: () {
                          setState(() {
                            _selectedLanguage = localSelectedLanguage; // Save changes to parent state
                            if(_selectedLanguage == "Tagalog") {
                              systemPrompt = "$localPromptText $_tagalogPrompt";
                            } else {
                              systemPrompt = localPromptText;
                            }
                            print("PROMPT: $systemPrompt");
                            Preferences.setSharedValue("sysPrompt", systemPrompt);
                            Preferences.setSharedValue("selectedLang", _selectedLanguage);
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 40), // Add some space at the top
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _resText,
                  style: TextStyle(fontSize: 23, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              _showTextInputDialog(context);
            },
            tooltip: 'Text Input',
            child: Icon(Icons.message_outlined),
          ),
          SizedBox(width: 10),
          /*FloatingActionButton(
            onPressed: _captureAndSaveImage,
            tooltip: 'Capture Image',
            child: Icon(Icons.camera_alt),
          ),*/
          FloatingActionButton(
            onPressed: () {
              _showConfigurationSheet(context); // Show the configuration modal
            },
            tooltip: 'Settings',
            child: const Icon(Icons.settings),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            //onPressed: _incrementCounter,
            //onPressed: _recorder.isRecording ? _stopRecording : _startRecording,
            onPressed: _isMonitoring ? stopMonitoring : startMonitoring,
            tooltip: 'Mic',
            //child: Icon(_recorder.isRecording ? Icons.mic : Icons.mic_off),
            child: Icon(_isMonitoring ? Icons.mic : Icons.mic_off),
          ),
        ],
      )
    );
  }
}*/
