import 'package:e_commerce_app/Screens/Cart.dart';
import 'package:e_commerce_app/Login_Signup/LoginScreen.dart';
import 'package:e_commerce_app/Screens/ContectUsPage.dart';
import 'package:e_commerce_app/Screens/OrderPlaced.dart';
import 'package:e_commerce_app/Screens/WishlistPage.dart';
import 'package:e_commerce_app/Screens/YourAccountPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:icons_plus/icons_plus.dart';


Future<void> main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HomePage(userEmail: '',));

}


class HomePage extends StatefulWidget {
  final String userEmail;
  const HomePage({super.key, required this.userEmail});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  final String category = "";



  final List<String> bannerImages = [
    "https://rukminim2.flixcart.com/fk-p-flap/1620/270/image/45348602ad4b2259.jpg?q=80",
    "https://rukminim2.flixcart.com/fk-p-flap/1620/270/image/193fafd4370237b8.jpg?q=80",
    "https://rukminim2.flixcart.com/fk-p-flap/1620/270/image/05cba11116281817.jpeg?q=80",
    "https://rukminim2.flixcart.com/fk-p-flap/1620/270/image/02cd5eda98fe68a7.jpg?q=80",
    "https://rukminim2.flixcart.com/fk-p-flap/1620/270/image/dcbd7ede32be1a39.jpeg?q=80"
  ];


  Future<String?> loadUserName() async{

    final emailToSearch = widget.userEmail.trim();
    final userName = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: emailToSearch).limit(1).get();

    if(userName.docs.isNotEmpty){
      final userData = userName.docs.first.data();
      return userData['username'] as String?;
    }
  }

  String? enteredUserName;
  String? _userId;

  Future<void> loadUserId() async{
    final emailToSearch = widget.userEmail.trim();
    final userid = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: emailToSearch).limit(1).get();

    if(userid.docs.isNotEmpty){
      final userId = userid.docs.first.id;
      setState(() {
        _userId = userId;
      });
    }
  }
  String? userCartId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUserNameData();
  }

  void _loadUserNameData() async{
    String? result = await loadUserName();
    if (mounted) {
      setState(() {
        enteredUserName = result;
      });
    }
  }




  Future<void> _addToCart(String productId,String productName,String imageUrl,double price) async{
    final emailToSearch = widget.userEmail.trim();

// Step 1️⃣: Check if this user already has a cart
    final existingCart = await FirebaseFirestore.instance
        .collection('carts')
        .where('email', isEqualTo: emailToSearch)
        .limit(1)
        .get();

    String cartId;

// Step 2️⃣: If user already has a cart → use same cart ID
    if (existingCart.docs.isNotEmpty) {
      cartId = existingCart.docs.first.id;
    } else {
      // Step 3️⃣: If no cart → generate new ID like C001, C002...
      QuerySnapshot allcart = await FirebaseFirestore.instance
          .collection('carts')
          .orderBy(FieldPath.documentId)
          .get();

      if (allcart.docs.isEmpty) {
        cartId = 'C001';
      } else {
        String lastCartId = allcart.docs.last.id;
        int lastNumber = int.parse(lastCartId.substring(1));
        int newNumber = lastNumber + 1;
        cartId = 'C${newNumber.toString().padLeft(3, '0')}';
      }

    }

// Step 4️⃣: Get userId using email
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: emailToSearch)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      print("❌ No user found with email $emailToSearch");
      return;
    }
    final userId = userSnapshot.docs.first.id;

// Step 5️⃣: Reference to user's cart
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);

// Step 6️⃣: Add product to cart (subcollection)
    await cartRef.collection('yourCart').doc(productId).set({
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': 1,
      'imageUrl': imageUrl,
    }, SetOptions(merge: true));

// Step 7️⃣: Save user details in cart document (only once)
    await cartRef.set({
      'userId': userId,
      'email': emailToSearch,
    }, SetOptions(merge: true));

    print("✅ Product added to cart ($cartId) for user: $emailToSearch");
  }

  void _viewDetails(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for $productName')),
    );
    // Add navigation logic here
  }


  // This is a placeholder for global state or temporary per-product state
  bool isProductInWishlist = false;
  Map<String, bool> wishlistStatus = {};
  String? wishlistId;

  Future<void> _toggleWishlist(String productId,String productName,String imageUrl,double price,double currentRating,int discount,int reviewCount,double strikeThrough) async{

    bool isFav = wishlistStatus[productId] ?? false;
    setState(() {
      wishlistStatus[productId] = !isFav;
    });


    final emailToSearch = widget.userEmail.trim();

    // If removing
    if (isFav) {
      await FirebaseFirestore.instance
          .collection('wishlists')
          .doc(wishlistId)
          .collection('yourWishlist')
          .doc(productId)
          .delete();

      print("❌ Removed from wishlist: $productId");
      return;
    }


    // Step 1️⃣: Check if this user already has a wishlist
    final existingWishlist = await FirebaseFirestore.instance
        .collection('wishlists')
        .where('email', isEqualTo: emailToSearch)
        .limit(1)
        .get();




// Step 2️⃣: If user already has a wishlist → use same wishlist ID
    if (existingWishlist.docs.isNotEmpty) {
      wishlistId = existingWishlist.docs.first.id;
    } else {
      // Step 3️⃣: If no cart → generate new ID like C001, C002...
      QuerySnapshot allwishlist = await FirebaseFirestore.instance
          .collection('wishlists')
          .orderBy(FieldPath.documentId)
          .get();

      if (allwishlist.docs.isEmpty) {
        wishlistId = 'W001';
      } else {
        String lastWishlistId = allwishlist.docs.last.id;
        int lastNumber = int.parse(lastWishlistId.substring(1));
        int newNumber = lastNumber + 1;
        wishlistId = 'W${newNumber.toString().padLeft(3, '0')}';
      }

    }

    // Step 4️⃣: Get userId using email
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: emailToSearch)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      print("❌ No user found with email $emailToSearch");
      return;
    }
    final userId = userSnapshot.docs.first.id;

// Step 5️⃣: Reference to user's wishlist
    final wishlistRef = FirebaseFirestore.instance.collection('wishlists').doc(wishlistId);

// Step 6️⃣: Add product to wishlist (subcollection)
    await wishlistRef.collection('yourWishlist').doc(productId).set({
      'productId': productId,
      'productName': productName,
      'price': price,
      'imageUrl': imageUrl,
      'currentRating': currentRating,
      'discount': discount,
      'reviewCount': reviewCount,
      'strikeThrough': strikeThrough
    }, SetOptions(merge: true));

// Step 7️⃣: Save user details in wishlist document (only once)
    await wishlistRef.set({
      'userId': userId,
      'email': emailToSearch,
    }, SetOptions(merge: true));

    print("✅ Product added to wishlist ($wishlistId) for user: $emailToSearch");
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


  final electronicsProducts = FirebaseFirestore.instance.collection('products').where('category', isEqualTo: 'Electronics');
  final fashionProducts = FirebaseFirestore.instance.collection('products').where('category', isEqualTo: 'Fashion');
  final sportsProducts = FirebaseFirestore.instance.collection('products').where('category', isEqualTo: 'Sports');

  final ScrollController _scrollController = ScrollController();


  final searchBar = TextEditingController();
  String selectedCategory = "";




  @override
  Widget build(BuildContext context) {



    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context){
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 70,
              shadowColor: Colors.black,
              elevation: 20,
              backgroundColor: Colors.indigo,
              title: Row(
                children: [
                  const Text("PROductADDa",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),),

                  //SearchBar
                  Padding(
                    padding: const EdgeInsets.only(left: 380.0),
                    child: SizedBox(
                        height: 40,
                        width: 360,
                        child: SearchBar(
                          controller: searchBar,
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value.trim();
                            });
                          },
                          trailing: [Icon(Icons.search)],
                          hintText: 'Search Product Category',
                        )
                    ),
                  ),
                ],
              ),
              actions: [



                //Cart Icon
                Padding(
                  padding: const EdgeInsets.only(right: 0.0),
                  child:
                      IconButton(
                          onPressed: (){
                            Navigator.of(context).push(MaterialPageRoute(builder: (context)=>CartPage(userEmail: widget.userEmail)));
                          },
                          icon: Row(
                            children: [
                              Icon(Icons.shopping_cart,color: Colors.white,size: 30,semanticLabel: 'Cart',),
                              SizedBox(width: 4,),
                              Text("Cart",style: TextStyle(fontSize: 15,color: Colors.white,fontWeight: FontWeight.bold),)
                            ],
                          ),
                  ),
                ),





                Padding(
                  padding: const EdgeInsets.only(right: 0.0),
                  child: TextButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ContactUsPage(userEmail: widget.userEmail)));
                    },
                    child: Text("Contact Us",style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold)),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: TextButton(
                    onPressed: (){},
                    child: Text("About Us",style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold)),
                  ),
                ),

                //Person Icon
                Padding(
                  padding: const EdgeInsets.only(right: 40.0),
                  child: PopupMenuButton<String>(
                    tooltip: "Profile",
                    icon: const Icon(Icons.person, size: 30,color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onSelected: (value) {
                      if (value == 'account') {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>YourAccountPage(userEmail: widget.userEmail)));
                        // Navigate to Account Page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Opening Account Page...")),
                        );
                      } else if (value == 'orders') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPlacedPage(userEmail: widget.userEmail)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Opening Orders...")),
                        );
                      } else if (value == 'wishlist') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => WishlistPage(userEmail: widget.userEmail)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Opening Wishlist...")),
                        );
                      } else if (value == 'settings') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Opening Settings...")),
                        );
                      } else if (value == 'logout') {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                        // Handle Logout logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Logged out successfully!")),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("👋 Hello, $enteredUserName",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'account',
                        child: ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Your Account'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'orders',
                        child: ListTile(
                          leading: Icon(Icons.shopping_bag),
                          title: Text('Your Orders'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'wishlist',
                        child: ListTile(
                          leading: Icon(Icons.favorite),
                          title: Text('Your Wishlist'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text('Logout',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),


            body: Center(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Text(
                      "Welcome To PROductADDa",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      children: [

                        //BannerImages
                        SizedBox(
                          height: 365,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0.0),
                            ),
                            margin: const EdgeInsets.only(left: 53.0,right: 53,top: 38),
                            elevation: 4,
                            child: CarouselSlider(
                              options: CarouselOptions(
                                height: 340, // Banner height
                                autoPlay: true, // Auto slide
                                enlargeCenterPage: true, // Zoom center image a bit
                                viewportFraction: 1, // Slight margin at sides
                                autoPlayInterval: Duration(seconds: 3), // Slide every 3 sec
                                autoPlayAnimationDuration: Duration(milliseconds: 800),
                              ),
                              items: bannerImages.map((url){
                                return Builder(builder: (context){
                                  return Image.network(url,fit: BoxFit.cover,width: double.infinity,);
                                });
                              }).toList(),
                            ),
                          ),
                        ),


                        if (selectedCategory.isEmpty || "electronics".contains(selectedCategory))
                        //Electronics
                        SizedBox(
                          height: 445,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0.0),
                            ),
                            margin: const EdgeInsets.only(left: 53.0,right: 53,top: 38),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20, top: 10),
                                  child: Text(
                                    "Electronics Store",
                                    style: TextStyle(
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                      stream: electronicsProducts.snapshots(),
                                      builder: (context, snapshot){

                                        if(snapshot.hasError){
                                          return const Center(child: Text("Something went wrong"));
                                        }
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }

                                        final data = snapshot.data!.docs;

                                        if (data.isEmpty) {
                                          return Center(child: Text("No products found in $category"));
                                        }


                                        return ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: data.length,
                                            itemBuilder: (context, index) {
                                              var product = data[index];

                                              // --- Dynamic Data Extraction ---
                                              final String cartProductId = product['productId'] as String;
                                              final String productName = product['name'] as String;
                                              final String imageUrl = product['imageUrl'];
                                              final double fetchedRating = (product['currentRating'] as num).toDouble();
                                              final int fetchedReviewCount = (product['reviewCount'] as num).toInt();
                                              final double actualPrice = (product['price'] as num).toDouble();
                                              final double strikeThroughPrice = (product['strikeThrough'] as num).toDouble();
                                              final int discountPercentage = (product['discount'] as num).toInt();
                                              final bool lastItem = index == (data.length) - 1;

                                              bool isFav = wishlistStatus[cartProductId] ?? false;

                                              return SizedBox(
                                                width: 230,
                                                child: Card(
                                                  elevation: 4,
                                                  margin: lastItem ? const EdgeInsets.only(top: 20, bottom: 20, left: 20,right: 20) : const EdgeInsets.only(top: 20, bottom: 20, left: 20),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: lastItem ? AspectRatio(
                                                          aspectRatio: 1.09,
                                                          child: Image.network(
                                                            product['imageUrl'] as String,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) =>
                                                            const Icon(Icons.broken_image, size: 60),
                                                          ),
                                                        ) : AspectRatio(
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
                                                            Text(
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                              productName,
                                                              style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16.5
                                                              ),
                                                            ),

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

                                                            SizedBox(height: 9,),
                                                            Row(
                                                              children: [
                                                                // Dynamic Strikethrough Price
                                                                Text(
                                                                  '₹${strikeThroughPrice.toStringAsFixed(0)}',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
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


                                                            const SizedBox(height: 5),

                                                            // --- Action Buttons ---
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: [
                                                                // 1. Wishlist Icon Button (Heart)
                                                                IconButton(
                                                                  padding: EdgeInsets.zero,
                                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                                  icon: Icon(
                                                                    isFav ? Icons.favorite : Icons.favorite_border,
                                                                    color: isFav ? Colors.red : Colors.grey[700],
                                                                    size: 20,
                                                                  ),
                                                                  onPressed: (){
                                                                    _toggleWishlist(cartProductId,productName,imageUrl,actualPrice,fetchedRating,discountPercentage,fetchedReviewCount,strikeThroughPrice);
                                                                  },

                                                                  tooltip: 'Add to Wishlist',
                                                                ),

                                                                const Spacer(), // Replaces SizedBox(width: 45)

                                                                // 2. View Details TextButton
                                                                TextButton(
                                                                  onPressed: () => _viewDetails(productName),
                                                                  style: TextButton.styleFrom(
                                                                    padding: EdgeInsets.zero,
                                                                    minimumSize: Size.zero,
                                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  ),
                                                                  child: const Text(
                                                                    'Details',
                                                                    style: TextStyle(
                                                                      color: Colors.black54,
                                                                      fontSize: 15,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),

                                                                const SizedBox(width: 8),

                                                                // 3. Add to Cart Button (Primary Action)
                                                                SizedBox(
                                                                  height: 32,
                                                                  child: ElevatedButton(
                                                                    onPressed: () => _addToCart(cartProductId,productName,imageUrl,actualPrice),
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.blueAccent,
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                      minimumSize: Size.zero,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(4),
                                                                      ),
                                                                    ),
                                                                    child: Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),

                                                                  ),
                                                                ),
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


                        if (selectedCategory.isEmpty || "fashion".contains(selectedCategory))
                        //Fashion
                        SizedBox(
                          height: 445,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0.0),
                            ),
                            margin: const EdgeInsets.only(left: 53.0,right: 53,top: 38),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20, top: 10),
                                  child: Text(
                                    "Best Value Deals on Fashion",
                                    style: TextStyle(
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                      stream: fashionProducts.snapshots(),
                                      builder: (context, snapshot){

                                        if(snapshot.hasError){
                                          return const Center(child: Text("Something went wrong"));
                                        }
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }

                                        final data = snapshot.data!.docs;

                                        if (data.isEmpty) {
                                          return Center(child: Text("No products found in $category"));
                                        }

                                        return ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: data.length,
                                            itemBuilder: (context, index) {
                                              var product = data[index];

                                              // --- Dynamic Data Extraction ---
                                              final String cartProductId = product['productId'] as String;
                                              final String productName = product['name'] as String;
                                              final String imageUrl = product['imageUrl'];
                                              final double fetchedRating = (product['currentRating'] as num).toDouble();
                                              final int fetchedReviewCount = (product['reviewCount'] as num).toInt();
                                              final double actualPrice = (product['price'] as num).toDouble();
                                              final double strikeThroughPrice = (product['strikeThrough'] as num).toDouble();
                                              final int discountPercentage = (product['discount'] as num).toInt();
                                              final bool lastItem = index == (data.length) - 1;

                                              bool isFav = wishlistStatus[cartProductId] ?? false;

                                              return SizedBox(
                                                width: 230,
                                                child: Card(
                                                  elevation: 4,
                                                  margin: lastItem ? const EdgeInsets.only(top: 20, bottom: 20, left: 20,right: 20) : const EdgeInsets.only(top: 20, bottom: 20, left: 20),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Container(
                                                          color: Colors.white, // Ensure a white background for non-filling images
                                                          child: lastItem ? AspectRatio(
                                                            aspectRatio: 1.09,
                                                            child: Image.network(
                                                              product['imageUrl'] as String,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) =>
                                                              const Icon(Icons.broken_image, size: 60),
                                                            ),
                                                          ) : AspectRatio(
                                                            aspectRatio: 1.2,
                                                            child: Image.network(
                                                              product['imageUrl'] as String,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) =>
                                                              const Icon(Icons.broken_image, size: 60),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 7),

                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 12.5,top: 6, right: 12.5),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                              productName,
                                                              style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16.5
                                                              ),
                                                            ),

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

                                                            SizedBox(height: 7.5,),
                                                            Row(
                                                              children: [
                                                                // Dynamic Strikethrough Price
                                                                Text(
                                                                  '₹${strikeThroughPrice.toStringAsFixed(0)}',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
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


                                                            const SizedBox(height: 5),

                                                            // --- Action Buttons ---
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: [
                                                                // 1. Wishlist Icon Button (Heart)
                                                                IconButton(
                                                                  padding: EdgeInsets.zero,
                                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                                  icon: Icon(
                                                                    isFav ? Icons.favorite : Icons.favorite_border,
                                                                    color: isFav ? Colors.red : Colors.grey[700],
                                                                    size: 20,
                                                                  ),
                                                                  onPressed: (){
                                                                    _toggleWishlist(cartProductId,productName,imageUrl,actualPrice,fetchedRating,discountPercentage,fetchedReviewCount,strikeThroughPrice);
                                                                  },
                                                                  tooltip: 'Add to Wishlist',
                                                                ),

                                                                const Spacer(), // Replaces SizedBox(width: 45)

                                                                // 2. View Details TextButton
                                                                TextButton(
                                                                  onPressed: () => _viewDetails(productName),
                                                                  style: TextButton.styleFrom(
                                                                    padding: EdgeInsets.zero,
                                                                    minimumSize: Size.zero,
                                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  ),
                                                                  child: const Text(
                                                                    'Details',
                                                                    style: TextStyle(
                                                                      color: Colors.black54,
                                                                      fontSize: 15,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),

                                                                const SizedBox(width: 8),

                                                                // 3. Add to Cart Button (Primary Action)
                                                                SizedBox(
                                                                  height: 32,
                                                                  child: ElevatedButton(
                                                                    onPressed: () => _addToCart(cartProductId,productName,imageUrl,actualPrice),
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.blueAccent,
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                      minimumSize: Size.zero,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(4),
                                                                      ),
                                                                    ),
                                                                    child: Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),

                                                                  ),
                                                                ),
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

                        if (selectedCategory.isEmpty || "sports".contains(selectedCategory))
                        //Sports
                        SizedBox(
                          height: 445,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0.0),
                            ),
                            margin: const EdgeInsets.only(left: 53.0,right: 53,top: 38),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20, top: 10),
                                  child: Text(
                                    "Top Sports Essentials",
                                    style: TextStyle(
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                      stream: sportsProducts.snapshots(),
                                      builder: (context, snapshot){

                                        if(snapshot.hasError){
                                          return const Center(child: Text("Something went wrong"));
                                        }
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }

                                        final data = snapshot.data!.docs;

                                        if (data.isEmpty) {
                                          return Center(child: Text("No products found in $category"));
                                        }

                                        return ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: data.length,
                                            itemBuilder: (context, index) {
                                              var product = data[index];

                                              // --- Dynamic Data Extraction ---
                                              final String cartProductId = product['productId'] as String;
                                              final String productName = product['name'] as String;
                                              final String imageUrl = product['imageUrl'];
                                              final double fetchedRating = (product['currentRating'] as num).toDouble();
                                              final int fetchedReviewCount = (product['reviewCount'] as num).toInt();
                                              final double actualPrice = (product['price'] as num).toDouble();
                                              final double strikeThroughPrice = (product['strikeThrough'] as num).toDouble();
                                              final int discountPercentage = (product['discount'] as num).toInt();
                                              final bool lastItem = index == (data.length) - 1;

                                              bool isFav = wishlistStatus[cartProductId] ?? false;


                                              return SizedBox(
                                                width: 230,
                                                child: Card(
                                                  elevation: 4,
                                                  margin: lastItem ? const EdgeInsets.only(top: 20, bottom: 20, left: 20,right: 20) : const EdgeInsets.only(top: 20, bottom: 20, left: 20),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Container(
                                                          color: Colors.white, // Ensure a white background for non-filling images
                                                          child: lastItem ? AspectRatio(
                                                            aspectRatio: 1.09,
                                                            child: Image.network(
                                                              product['imageUrl'] as String,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) =>
                                                              const Icon(Icons.broken_image, size: 60),
                                                            ),
                                                          ) : AspectRatio(
                                                            aspectRatio: 1.2,
                                                            child: Image.network(
                                                              product['imageUrl'] as String,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) =>
                                                              const Icon(Icons.broken_image, size: 60),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 7),

                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 12.5,top: 6, right: 12.5),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                              productName,
                                                              style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16.5
                                                              ),
                                                            ),

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

                                                            SizedBox(height: 7.5,),
                                                            Row(
                                                              children: [
                                                                // Dynamic Strikethrough Price
                                                                Text(
                                                                  '₹${strikeThroughPrice.toStringAsFixed(0)}',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
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


                                                            const SizedBox(height: 5),

                                                            // --- Action Buttons ---
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: [
                                                                // 1. Wishlist Icon Button (Heart)
                                                                IconButton(
                                                                  padding: EdgeInsets.zero,
                                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                                  icon: Icon(
                                                                    isFav ? Icons.favorite : Icons.favorite_border,
                                                                    color: isFav ? Colors.red : Colors.grey[700],
                                                                    size: 20,
                                                                  ),
                                                                  onPressed: (){
                                                                    _toggleWishlist(cartProductId,productName,imageUrl,actualPrice,fetchedRating,discountPercentage,fetchedReviewCount,strikeThroughPrice);
                                                                  },
                                                                  tooltip: 'Add to Wishlist',
                                                                ),

                                                                const Spacer(), // Replaces SizedBox(width: 45)

                                                                // 2. View Details TextButton
                                                                TextButton(
                                                                  onPressed: () => _viewDetails(productName),
                                                                  style: TextButton.styleFrom(
                                                                    padding: EdgeInsets.zero,
                                                                    minimumSize: Size.zero,
                                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  ),
                                                                  child: const Text(
                                                                    'Details',
                                                                    style: TextStyle(
                                                                      color: Colors.black54,
                                                                      fontSize: 15,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),

                                                                const SizedBox(width: 8),

                                                                // 3. Add to Cart Button (Primary Action)
                                                                SizedBox(
                                                                  height: 32,
                                                                  child: ElevatedButton(
                                                                    onPressed: () => _addToCart(cartProductId,productName,imageUrl,actualPrice),
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.blueAccent,
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                      minimumSize: Size.zero,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(4),
                                                                      ),
                                                                    ),
                                                                    child: Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),

                                                                  ),
                                                                ),
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

                        //Fixed FOOTER
                        Padding(
                          padding: const EdgeInsets.only(top: 100.0),
                          child: Container(
                            width: double.infinity,
                            color: Color(0xFF222E3C),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [

                                //Back To Top Button
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: (){
                                      _scrollController.animateTo(
                                          0,
                                          duration: Duration(milliseconds: 600),
                                          curve: Curves.easeInOut
                                      );
                                    },
                                    child: Container(
                                      height: 45,
                                      width: double.maxFinite,
                                      color: Color(0xFF38485B),
                                      child: Center(
                                        child: Text(
                                          'Back To Top',
                                          style: TextStyle(fontSize: 14, color: Colors.white,),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),



                                //Main Footer
                                Padding(
                                  padding: const EdgeInsets.only(top: 50.0,right: 130,bottom: 30,left: 130),

                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [

                                      //About
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("About",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold,),),
                                          SizedBox(height: 7,),

                                          FooterLink(
                                              onTap: (){},
                                              text: "About Us"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Our Story"),
                                          FooterLink(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => ContactUsPage(userEmail: widget.userEmail)));
                                              },
                                              text: "Contact Us"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Careers"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Press / Media"),
                                        ],
                                      ),

                                      //Consumer POlicy
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Consumer Policy",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold,)),
                                          SizedBox(height: 7,),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Cancellation & Returns"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Terms Of Use"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Security"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Privacy"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Cookie Policy"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Grievance Redressal"),
                                        ],
                                      ),

                                      //Let Us Help You
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Let Us Help You",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold,)),
                                          SizedBox(height: 7,),
                                          FooterLink(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => YourAccountPage(userEmail: widget.userEmail)));
                                              },
                                              text: "Your Account"),
                                          FooterLink(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage(userEmail: widget.userEmail)));
                                              },
                                              text: "Your Cart"),
                                          FooterLink(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPlacedPage(userEmail: widget.userEmail)));
                                              },
                                              text: "Your Orders"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Returns Center"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Gift Cards"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Help"),
                                        ],
                                      ),

                                      //Help
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Help",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold,)),
                                          SizedBox(height: 7,),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Payment"),
                                          FooterLink(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPlacedPage(userEmail: widget.userEmail)));
                                              },
                                              text: "Shipping"),
                                          FooterLink(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPlacedPage(userEmail: widget.userEmail)));
                                              },
                                              text: "Track Order"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Cancellation & Returns"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "FAQ"),
                                          FooterLink(
                                              onTap: (){},
                                              text: "Report an Issue"),

                                        ],
                                      ),

                                      Container(
                                        width: 1.5,
                                        height: 150,
                                        color: Colors.white.withOpacity(0.3), // subtle divider
                                      ),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Mail Us",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold,)),
                                          SizedBox(height: 7,),
                                          Text("PROductADDa Internet Private Limited,",style: TextStyle(color: Color(0xFFBDC8D3),fontSize: 16,)),
                                          Text("dhairyasoni@gmail.com",style: TextStyle(fontSize: 16,color:Color(0xFFBDC8D3))),
                                          SizedBox(height: 15,),
                                          Text("Social",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white)),
                                          SizedBox(height: 2,),
                                          Row(
                                            children: [
                                              IconButton(color: Colors.blue,onPressed: (){}, icon: Logo(Logos.facebook_logo, size: 27),),
                                              IconButton(color: Color(0xFFBDC8D3),onPressed: (){}, icon: Logo(Logos.instagram, size: 27),),
                                              IconButton(color: Color(0xFFBDC8D3),onPressed: (){}, icon: Logo(Logos.facebook_messenger, size: 27),),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),


                                //Bottom Footer
                                Container(
                                  height: 55,
                                  width: double.maxFinite,
                                  color: Color(0xFF10161C),
                                  child: Center(
                                    child: Text(
                                      '© 2025 PROductADDa. All rights reserved.',
                                      style: TextStyle(fontSize: 14, color: Colors.white,),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )



                      ],
                    ),
                  ),


                ],
              ),
            ),


          );
        },
      ),
    );
  }
}




class FooterLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const FooterLink({super.key, required this.text, required this.onTap});

  @override
  State<FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<FooterLink> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),

      onTap: widget.onTap,


      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        style: TextStyle(
          color: _isPressed ? Colors.orangeAccent : Color(0xFFBDC8D3),
          fontSize: _isPressed ? 17 : 16,
          fontWeight: FontWeight.w400,
        ),
        child: Text(widget.text),
      ),
    );
  }
}