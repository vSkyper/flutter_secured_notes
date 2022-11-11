import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encrypted.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';
import 'package:secured_notes/views/settings.dart';

class Home extends StatefulWidget {
  final String note;
  final VoidCallback closeNote;
  const Home({super.key, required this.note, required this.closeNote});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _noteController.text = widget.note;
  }

  @override
  void dispose() {
    super.dispose();

    _noteController.dispose();
  }

  Future saveNote() async {
    final BiometricStorageFile biometricStorage = await BiometricStorage().getStorage('key');
    final String? key;
    try {
      key = await biometricStorage.read();
    } on AuthException catch (e) {
      Utils.showSnackBar(e.message);
      return;
    }
    if (key == null) return;

    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? data = await storage.read(key: 'data');
    if (data == null) return;

    final Uint8List iv = Encryption.secureRandom(12);

    Encrypted encrypted = Encrypted(
        salt: Encrypted.deserialize(data).salt,
        iv: Encryption.toBase64(iv),
        note: Encryption.encryptChaCha20Poly1305(_noteController.text.trim(), Encryption.fromBase64(key), iv));

    await storage.write(key: 'data', value: Encrypted.serialize(encrypted));

    Utils.showSnackBar('The note has been saved');
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
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Settings(closeNote: widget.closeNote)),
              ),
            ),
            IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: widget.closeNote,
            ),
          ],
        ),
        body: SingleChildScrollView(
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
                maxLines: 8,
                decoration: const InputDecoration.collapsed(
                  hintText: "Enter your note here",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: saveNote,
                icon: const Icon(Icons.save),
                label: const Text('Save note'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
