import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/movie.dart';

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController title = TextEditingController();
  TextEditingController desc  = TextEditingController();
  TextEditingController duration = TextEditingController();
  TextEditingController seats = TextEditingController(text: "47");
  List<TextEditingController> slots = [TextEditingController()];

  File? selectedImage;

  // ------------------- Pick from gallery -------------------
  Future pickFromGallery() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => selectedImage = File(img.path));
  }


  // --------------------------- SAVE ---------------------------
  saveMovie(){
    if(selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload movie image"), backgroundColor: Colors.red)
      );
      return;
    }

    if(!_formKey.currentState!.validate()) return;

    Movie m = Movie(
      id: const Uuid().v4(),
      title: title.text.trim(),
      description: desc.text.trim(),
      imageUrl: selectedImage!.path,   
      duration: int.parse(duration.text.trim()),
      timeSlots: slots.map((e)=>e.text.trim()).toList(),
    );

    Navigator.pop(context,m);
  }

  @override
  Widget build(context){
    return Scaffold(
      backgroundColor: const Color(0xff0B121E),
      appBar: AppBar(
        backgroundColor: const Color(0xff0B121E),
        title: const Text("Add New Movie",style: TextStyle(color:Colors.white,fontSize:19)),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key:_formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Movie Image *",
                style: TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w600)),

              const SizedBox(height:12),

              Row(
                children: [
                  Expanded(child: imageButton("Upload Image",Icons.upload,pickFromGallery)),
                  const SizedBox(width:12)
                ],
              ),

              const SizedBox(height:26),
              label("Movie Title *"),
              input(title,"Enter movie title"),

              const SizedBox(height:22),
              label("Description *"),
              input(desc,"Enter movie description",max:3),

              const SizedBox(height:22),
              label("Movie Duration (minutes) *"),
              input(duration,"120",keyboard:TextInputType.number),

              const SizedBox(height:22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  label("Time Slots (Max 5)"),
                  GestureDetector(
                    onTap: slots.length<5 ? ()=>setState(()=>slots.add(TextEditingController())) : null,
                    child: const Text("+ Add Slot",style:TextStyle(color:Colors.red,fontWeight:FontWeight.w600)),
                  )
                ],
              ),

              const SizedBox(height:10),
              Column(
                children: List.generate(slots.length,(i)=>
                    Row(
                      children: [
                        Expanded(child: input(slots[i],"10:00 AM")),
                        IconButton(onPressed:()=>setState(()=>slots.removeAt(i)),icon:const Icon(Icons.delete,color:Colors.red))
                      ],
                    )
                ),
              ),

              const SizedBox(height:22),
              label("Number of Seats"),
              input(seats,"47",keyboard: TextInputType.number),

              const SizedBox(height:35),
              Row(
                children: [
                  Expanded(child: cancelBtn()),
                  const SizedBox(width:14),
                  Expanded(child: addBtn()),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI Components ----------------

  Widget input(TextEditingController c,String h,{int max=1,keyboard=TextInputType.text})=>TextFormField(
    controller:c,
    maxLines:max,
    keyboardType:keyboard,
    validator:(v)=>v!.isEmpty?"Required":null,
    style:const TextStyle(color:Colors.white),
    decoration:InputDecoration(
      filled:true,
      fillColor:const Color(0xff121C29),
      hintText:h,
      hintStyle:const TextStyle(color:Colors.white38),
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide.none),
    ),
  );

  Widget imageButton(String text,IconData icon,Function() action)=>GestureDetector(
    onTap: action,
    child: Container(
      height:65,
      decoration: BoxDecoration(
        border: Border.all(color:Colors.white30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Icon(icon,color:Colors.white70),
            const SizedBox(height:5),
            Text(text,style:const TextStyle(color:Colors.white70,fontSize:13))
          ],
        ),
      ),
    ),
  );

  Widget label(text)=>Text(text,style:const TextStyle(color:Colors.white70,fontSize:15,fontWeight:FontWeight.bold));

  Widget cancelBtn()=>OutlinedButton(
    onPressed:()=>Navigator.pop(context),
    style:OutlinedButton.styleFrom(
        side:const BorderSide(color:Colors.white70,width:1.3),
        padding:const EdgeInsets.symmetric(vertical:14)),
    child:const Text("Cancel",style:TextStyle(color:Colors.white70,fontSize:15)),
  );

  Widget addBtn()=>ElevatedButton(
    onPressed: saveMovie,
    style:ElevatedButton.styleFrom(
      backgroundColor:const Color(0xffE50914),
      padding:const EdgeInsets.symmetric(vertical:14)),
    child:const Text("Add Movie",style:TextStyle(color:Colors.white,fontSize:16)),
  );
}
