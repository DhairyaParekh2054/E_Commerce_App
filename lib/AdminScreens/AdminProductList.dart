import 'package:e_commerce_app/AdminScreens/AddProduct.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';


class AdminProductList extends StatefulWidget {
  const AdminProductList({super.key});

  @override
  State<AdminProductList> createState() => _AdminProductListState();
}

class _AdminProductListState extends State<AdminProductList> {

  String? selectCategory;
  final List<String> searchProduct = [
    'Electronics',
    'Fashion',
    'Sports',
    'Beauty',
    'Books'
  ];

  
  
  @override
  Widget build(BuildContext context) {

    //Product Id
    FirebaseFirestore.instance.collection('products')
        .get()
        .then((snapshot)=>snapshot.docs.map((doc){
            final data = doc.data();
            data['id']=doc.id;
            return data;
        }).toList());

    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text("Manage Products",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 40),),
              SizedBox(height: 40,),
              Row(
                // mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Add Product",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),),
                  SizedBox(width: 10,),
                  FloatingActionButton(
                      child: Icon(Icons.add_circle_outline),
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>AddProductPage(productId: null,)));
                      }
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 14,bottom: 14),
                child: Divider(),
              ),

              Row(
                children: [
                  Text("Search Product By Category: ",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),

                  SizedBox(width: 13,),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectCategory,
                        decoration: InputDecoration(labelText: "Category"),
                        alignment: Alignment.centerLeft,
                        icon: Icon(Icons.arrow_drop_down),
                        hint: Text("Search Product"),
                        items: searchProduct.map((cat) => DropdownMenuItem(value: cat,child: Text(cat))).toList(),
                        onChanged: (value){
                          setState(() {
                            selectCategory=value!;
                          });
                        }
                    ),
                  ),

                ],
              ),

              SizedBox(height: 30,),

              if (selectCategory == null)
                Expanded(
                  child: Center(
                    child: Text(
                      "Please select a category to view products.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('products')
                        .where('category', isEqualTo: selectCategory)
                        .snapshots(),
                    builder: (context, snapshot){
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No products found in $selectCategory category.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      final data = snapshot.data!.docs;

                      return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            var product = data[index];

                            return SizedBox(
                              height: 80,
                              width: 230,
                              child: Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(
                                    top: 20, bottom: 20, left: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AspectRatio(
                                        aspectRatio: 1.2,
                                        child: Image.network(
                                          product['imageUrl'] as String,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 60),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    Padding(
                                      padding: const EdgeInsets.only(left: 12.5,top: 6, right: 12.5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("${product.id}",
                                                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17),),
                                              Text(
                                                product['name'],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15.5
                                                ),
                                              ),
                                              Text("₹${product['price']}",
                                                style: TextStyle(fontSize: 17),),
                                            ],
                                          ),
                                          SizedBox(height: 7,),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton(onPressed: (){
                                                setState(() {
                                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>AddProductPage(productId: product.id)));
                                                });
                                              }, child: Text("Update")),

                                              Spacer(),

                                              ElevatedButton(onPressed: (){
                                                setState(() {
                                                  showDialog(
                                                      context: context,
                                                      barrierDismissible: true,
                                                      builder: (context){
                                                        return AlertDialog(
                                                          alignment: Alignment.bottomCenter,
                                                          title: Text("Delete Product"),
                                                          content: Text("Are You Sure Want To Delete This Product ?"),
                                                          actions: [
                                                            TextButton(onPressed: (){
                                                              Navigator.of(context).pop();
                                                            }, child: Text("Cancel")),
                                                            TextButton(onPressed: (){
                                                              FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                                                              Navigator.of(context).pop();
                                                            }, child: Text("Delete")),
                                                          ],
                                                        );
                                                      }
                                                  );

                                                });
                                              }, child: Text("Delete")),

                                            ],
                                          ),

                                        ],
                                      ),
                                    ),

                                  ],
                                ),
                              ),

                            );
                          }
                      );
                    }
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}


