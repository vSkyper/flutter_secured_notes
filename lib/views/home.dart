import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/data.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/views/settings.dart';

class Home extends StatefulWidget {
  final Uint8List key_;
  final String note;
  final VoidCallback closeNote;
  const Home({super.key, required this.key_, required this.note, required this.closeNote});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _noteController = TextEditingController();
  late Uint8List _key;

  @override
  void initState() {
    super.initState();

    _key = widget.key_;
    _noteController.text = widget.note;
    _noteController.addListener(saveNote);
  }

  @override
  void dispose() {
    super.dispose();

    _noteController.dispose();
  }

  Future saveNote() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? encrypted = await storage.read(key: 'data');
    if (encrypted == null) return;

    final Uint8List ivNote = Encryption.secureRandom(12);

    Data data = Data(
      salt: Data.deserialize(encrypted).salt,
      ivKey: Data.deserialize(encrypted).ivKey,
      keyEncrypted: Data.deserialize(encrypted).keyEncrypted,
      ivNote: Encryption.toBase64(ivNote),
      noteEncrypted: Encryption.encrypt(_noteController.text, _key, ivNote),
    );

    await storage.write(key: 'data', value: Data.serialize(data));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Home'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Settings()),
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: widget.closeNote,
            ),
          ],
        ),
        body: Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your note',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  keyboardType: TextInputType.multiline,
                  minLines: 8,
                  maxLines: null,
                  decoration: const InputDecoration.collapsed(
                    hintText: "Enter your note here",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
