import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';


Future<void> main() async{
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const WishlistPage(userEmail: '',));
}

class WishlistPage extends StatefulWidget {
  final String userEmail;
  const WishlistPage({super.key, required this.userEmail});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {

  String? wishlistId;
  Stream<QuerySnapshot> streamWishlist() async*{
    final userEmail = widget.userEmail.trim();
    if(userEmail != widget.userEmail){
      await Future.delayed(Duration(microseconds: 200));

      yield* Stream.empty();
      return;
    }

    final wishlistDoc = await FirebaseFirestore.instance.collection('wishlists')
        .where('email', isEqualTo: userEmail).limit(1).get();

    if(wishlistDoc.docs.isNotEmpty){
       wishlistId = wishlistDoc.docs.first.id;

      yield* FirebaseFirestore.instance.collection('wishlists').doc(wishlistId).collection('yourWishlist').snapshots();
    }

  }

  Widget _buildRatingStarRow(double rating) {
    List<Widget> stars = [];
    const int maxStars = 5;
    final int filledStars = rating.floor();

    for (int i = 0; i < maxStars; i++) {
      Icon starIcon;

      if (i < filledStars) {
        starIcon = const Icon(Icons.star, color: Colors.amber, size: 16);
      } else if (i == filledStars && (rating - filledStars) >= 0.5) {
        starIcon = const Icon(Icons.star_half, color: Colors.amber, size: 16);
      } else {
        starIcon = const Icon(Icons.star_border, color: Colors.amber, size: 16);
      }

      stars.add(starIcon);
    }


    return Row(
        mainAxisSize: MainAxisSize.min,
        children: stars
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),
          title: Text("Wishlist Page"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20,left: 40,bottom: 20,right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 25.0),
                  child: Text("Your Wishlist",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 45),),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: streamWishlist(),
                    builder: (context, snapshot){

                      // 1️⃣ Check for errors
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      // 2️⃣ Show loading indicator while waiting
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // 3️⃣ Check if no data or empty
                      if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No items in your wishlist.'));
                      }

                      final wishlist = snapshot.data!.docs;

                      return GridView.builder(
                        itemCount: wishlist.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                            childAspectRatio: 0.8,
                              crossAxisSpacing: 6,
                            mainAxisSpacing: 10
                          ),
                          itemBuilder: (context, index){


                            var wishlistItems = wishlist[index].data() as Map<String, dynamic>;

                            final double fetchedRating = (wishlistItems['currentRating'] as num).toDouble();
                            final double fetchedReviewCount = (wishlistItems['reviewCount'] as num).toDouble();
                            final double strikeThroughPrice = (wishlistItems['strikeThrough'] as num).toDouble();
                            final double actualPrice = (wishlistItems['price'] as num).toDouble();
                            final double discountPercentage = (wishlistItems['discount'] as num).toDouble();

                            Map<String, bool> wishlistStatus = {};
                            String productId = wishlist[index].id;  // Firestore doc id
                            bool isFav = wishlistStatus[productId] ?? true;  // since it's already in wishlist page

                            return Card(
                              elevation: 9,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15.0,right: 15,top: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    //Item Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        color: Colors.white, // Ensure a white background for non-filling images
                                        child: AspectRatio(
                                          aspectRatio: 1.4,
                                          child: Image.network(
                                            wishlistItems['imageUrl'] as String,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 60),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                      height: 10,
                                    ),
                                    //Item Name
                                    Text(
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      wishlistItems['productName'],style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),


                                    Row(
                                      children: [
                                        // Dynamic Rating
                                        _buildRatingStarRow(fetchedRating),

                                        const SizedBox(width: 6),

                                        // Dynamic Score and Review Count
                                        Text(
                                          '${fetchedRating.toStringAsFixed(1)} ($fetchedReviewCount)',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        ),
                                      ],
                                    ),


                                    SizedBox(height: 4.5,),
                                    Row(
                                      children: [
                                        // Dynamic Strikethrough Price
                                        Text(
                                          '₹${strikeThroughPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                            decorationColor: Colors.grey,
                                            decorationThickness: 1.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6,),
                                        // Dynamic Actual Price
                                        Text("₹${actualPrice.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                              fontSize: 16
                                          ),
                                        ),
                                        const SizedBox(width: 6,),
                                        // Dynamic Discount Percentage
                                        Text("- $discountPercentage%",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green
                                          ),
                                        ),
                                      ],
                                    ),


                                    const SizedBox(height: 3.5),

                                    // --- Action Buttons ---
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // 1. Wishlist Icon Button (Heart)
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            color: isFav ? Colors.red : Colors.grey,
                                            size: 23,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              wishlistStatus[productId] = !isFav;   // toggle only THIS item
                                            });

                                            // Also update firebase (remove or add)
                                            if (isFav) {
                                              FirebaseFirestore.instance
                                                  .collection('wishlists')
                                                  .doc(wishlistId)
                                                  .collection('yourWishlist')
                                                  .doc(productId)
                                                  .delete();
                                            }
                                          },
                                        ),


                                        const Spacer(), // Replaces SizedBox(width: 45)

                                        // 2. View Details TextButton
                                        // TextButton(
                                        //   onPressed: () => _viewDetails(productName),
                                        //   style: TextButton.styleFrom(
                                        //     padding: EdgeInsets.zero,
                                        //     minimumSize: Size.zero,
                                        //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        //   ),
                                        //   child: const Text(
                                        //     'Details',
                                        //     style: TextStyle(
                                        //       color: Colors.black54,
                                        //       fontSize: 15,
                                        //       fontWeight: FontWeight.w500,
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
