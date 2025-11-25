import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';


class AddProductPage extends StatefulWidget {
  final String? productId;
  const AddProductPage({super.key,required this.productId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  TextEditingController pIdController = TextEditingController();
  final pNameController = TextEditingController();
  final pDesController = TextEditingController();
  final pPriceController = TextEditingController();
  final pImageUrlController = TextEditingController();

  final pStrikeThroughPriceController = TextEditingController();
  final pDiscountController = TextEditingController();
  final pCurrentRatingController = TextEditingController();
  final pReviewCountController = TextEditingController();

  String? selectCate;
  final List<String> pCat = [
      'Electronics',
      'Fashion',
      'Sports',
      'Beauty',
      'Books'
  ];

  void clearFields() {
    pIdController.clear();
    pNameController.clear();
    pPriceController.clear();
    pDesController.clear();
    pImageUrlController.clear();
    pStrikeThroughPriceController.clear();
    pDiscountController.clear();
    pCurrentRatingController.clear();
    pReviewCountController.clear();
    setState(() {
      selectCate = null;
    });
  }






  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pIdController = TextEditingController(text: widget.productId ?? '');
    loadProduct();
  }

  @override
  void dispose() {
    pIdController.dispose();
    super.dispose();
  }

  //Get All Fields/Fetch Data
  bool _loading = true;
  Future<void> loadProduct() async{
    final doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();

    if(doc.exists){
      final data = doc.data();
      pNameController.text = data?['name'] ?? '';
      pPriceController.text = data!['price'].toString();
      pDesController.text = data?['description'] ?? '';
      pImageUrlController.text = data?['imageUrl'] ?? '';
      pStrikeThroughPriceController.text = data!['strikeThrough'].toString();
      pDiscountController.text = data!['discount'].toString();
      pCurrentRatingController.text = data!['currentRating'].toString();
      pReviewCountController.text = data!['reviewCount'].toString();
      selectCate = data['category'] ?? '';

    }

    setState(() {
      _loading = false;
    });
  }


  //Add Product
  Future<void> addProduct() async {

    final productId = pIdController.text.trim();
    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Product ID.")),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('products').doc(productId);
    try {
      final docSnapshot = await docRef.get();

      //Product Id is already exists: show error
      if (docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product ID is already exists, enter a new product ID."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }


      //Product id is new: then save product
      await docRef.set({
        'productId': productId,
        'name': pNameController.text,
        'description': pDesController.text,
        'price': double.tryParse(pPriceController.text) ?? 0.0,
        'category': selectCate,
        'imageUrl': pImageUrlController.text,
        'strikeThrough': double.tryParse(pStrikeThroughPriceController.text) ?? 0.0,
        'discount': double.tryParse(pDiscountController.text) ?? 0.0,
        'currentRating': double.tryParse(pCurrentRatingController.text) ?? 0.0,
        'reviewCount': double.tryParse(pReviewCountController.text) ?? 0.0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Added Successfully")),
      );

      clearFields();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ERROR: $e")),
      );
    }
  }


  //Update Product
  Future<void> updateProduct() async {

    await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
      'name': pNameController.text,
      'description': pDesController.text,
      'price': double.tryParse(pPriceController.text) ?? 0.0,
      'category': selectCate,
      'imageUrl': pImageUrlController.text,
      'strikeThrough': double.tryParse(pStrikeThroughPriceController.text) ?? 0.0,
      'discount': double.tryParse(pDiscountController.text) ?? 0.0,
      'currentRating': double.tryParse(pCurrentRatingController.text) ?? 0.0,
      'reviewCount': double.tryParse(pReviewCountController.text) ?? 0.0,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product Added Successfully")),
    );

    clearFields();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),
            title: Text("Admin Panel"),
            backgroundColor: Colors.blueAccent,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 200.0,right: 200,top: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    //Id
                    TextField(
                      controller: pIdController,
                      decoration: InputDecoration(
                          label: Text("Product Id"),
                          border: OutlineInputBorder()
                      ),
                    ),

                    SizedBox(height: 20,),

                    //Category
                    DropdownButtonFormField<String>(
                      value: selectCate,
                      decoration: InputDecoration(labelText: "Category"),
                      alignment: Alignment.centerLeft,
                      icon: Icon(Icons.arrow_drop_down),
                      hint: Text("Product Category"),

                      items: pCat.map((cat) => DropdownMenuItem(value: cat,child: Text(cat))).toList(),
                      onChanged: (value){
                        setState(() {
                          selectCate=value;
                        });
                      },
                    ),

                    SizedBox(height: 20,),

                    //Name
                    TextField(
                      controller: pNameController,
                      decoration: InputDecoration(
                          label: Text("Product Name"),
                          border: OutlineInputBorder()
                      ),
                    ),

                    SizedBox(height: 20,),

                    //Description
                    TextField(
                      controller: pDesController,
                      decoration: InputDecoration(
                          label: Text("Product Description"),
                          border: OutlineInputBorder()
                      ),
                    ),

                    SizedBox(height: 20,),

                    //ImageUrl
                    TextField(
                      controller: pImageUrlController,
                      decoration: InputDecoration(
                          label: Text("Image Url"),
                          border: OutlineInputBorder()
                      ),
                    ),

                    SizedBox(height: 20,),

                    Row(
                      children: [

                        //Price
                        Expanded(
                          child: TextField(
                            controller: pPriceController,
                            decoration: InputDecoration(
                                label: Text("Product Price"),
                                border: OutlineInputBorder()
                            ),
                          ),
                        ),

                        SizedBox(width: 35,),


                        //StrikeThrough
                        Expanded(
                          child: TextField(
                            controller: pStrikeThroughPriceController,
                            decoration: InputDecoration(
                                label: Text("Strike Through Price"),
                                border: OutlineInputBorder()
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20,),

                    Row(
                      children: [

                        //Discount
                        Expanded(
                          child: TextField(
                            controller: pDiscountController,
                            decoration: InputDecoration(
                                label: Text("Discount"),
                                border: OutlineInputBorder()
                            ),
                          ),
                        ),

                        SizedBox(width: 20,),


                        //Current Rating
                        Expanded(
                          child: TextField(
                            controller: pCurrentRatingController,
                            decoration: InputDecoration(
                                label: Text("Current Rating"),
                                border: OutlineInputBorder()
                            ),
                          ),
                        ),

                        SizedBox(width: 20,),

                        //Review Count
                        Expanded(
                          child: TextField(
                            controller: pReviewCountController,
                            decoration: InputDecoration(
                                label: Text("Review Count"),
                                border: OutlineInputBorder()
                            ),
                          ),
                        )
                      ],
                    ),


                    SizedBox(height: 40,),

                    Row(
                      children: [
                        ElevatedButton(onPressed: addProduct, child: Text("Save")),
                        SizedBox(width: 20,),
                        ElevatedButton(onPressed: () async{
                          updateProduct();
                        }, child: Text("Update")),
                      ],
                    ),

                  ],
                ),
              ),
            ),
          )
      ),
    );
  }

}
