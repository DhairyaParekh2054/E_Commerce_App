  // order (collection)
    // - OR001(doc)
      //  -orderId
      //  -userId
      //  -email
      //  -orderedDate
      //  -shippedDate
      //  -inTransitDate
      //  -outDiliveredDate
      //  -deliveredDate
      //  -subTotal
      //  -CGST
      //  -SGST
      //  -grandTotal
      //  -paymentMethod (upi/visa credit card/rupay credit card/....)
      //  -shippingStatus (order con/shipped/inTansit/outOfDelivery/delivered)
      //  -orderStatus (recent/previous)

      //  -yourOrderedItem (sub collection)
          //    -imageUrl
          //    -productName
          //    -price
          //    -quantity
          //    -itemTotalPrice
          //    -itemStatus (ordered/shipped/canceled/exchanged)



  import 'package:flutter/material.dart';
  import 'package:e_commerce_app/firebase_options.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:timeline_tile/timeline_tile.dart';
  import 'package:intl/intl.dart';

  Future<void> main() async{
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const OrderPlacedPage(userEmail: '',));
  }

  // 1. Define the data structure for the steps
  class TrackingStep {
    final String title;
    final String date;
    final bool isCompleted;
    final bool isCurrent;

    TrackingStep(this.title, this.date, {this.isCompleted = false, this.isCurrent = false});
  }


  class OrderPlacedPage extends StatefulWidget {
    final String userEmail;
    const OrderPlacedPage({super.key, required this.userEmail});

    @override
    State<OrderPlacedPage> createState() => _OrderPlacedPageState();
  }

  class _OrderPlacedPageState extends State<OrderPlacedPage> {


    //Recent Orders
    String? recentOrderId;
    Stream<QuerySnapshot<Map<String, dynamic>>> streamRecentOrderDetails() {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: widget.userEmail)
          .where('orderStatus', isEqualTo: 'recent')
          .snapshots();
    }

    Stream<QuerySnapshot> streamRecentOrderItems() async* {
      // Step 1: Get the recent order document
      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: widget.userEmail)
          .where('orderStatus', isEqualTo: 'recent')
          .limit(1)
          .get();

      recentOrderId = orderSnap.docs.first.id;

      // Step 2: Stream subcollection of that order
      yield* FirebaseFirestore.instance
          .collection('orders')
          .doc(recentOrderId)
          .collection('yourOrderedItems')
          .snapshots();
    }


    Stream<QuerySnapshot> streamRecentPaymentInfo() {
      return FirebaseFirestore.instance.collection('orders').where('email', isEqualTo: widget.userEmail)
          .where('orderStatus', isEqualTo: 'recent').snapshots();
    }

    Future<DocumentSnapshot?> futureRecentUserInfo() async {
      final userSnap = await FirebaseFirestore.instance.collection('users')
          .where('email', isEqualTo: widget.userEmail).limit(1).get();
      if(userSnap.docs.isNotEmpty){
        return userSnap.docs.first;
      }
      return null;
    }


    //Privious Orders
    String? previousOrderId;
    Stream<QuerySnapshot<Map<String, dynamic>>> streamPreviousOrderDetails() {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: widget.userEmail)
          .where('orderStatus', isEqualTo: 'previous')
          .snapshots();
    }

    Stream<QuerySnapshot> streamPreviousOrderItems() async* {
      // Step 1: Get the recent order document
      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: widget.userEmail)
          .where('orderStatus', isEqualTo: 'previous')
          .limit(1)
          .get();

      previousOrderId = orderSnap.docs.first.id;

      // Step 2: Stream subcollection of that order
      yield* FirebaseFirestore.instance
          .collection('orders')
          .doc(previousOrderId)
          .collection('yourOrderedItems')
          .snapshots();
    }


    Stream<QuerySnapshot> streamPreviousPaymentInfo() {
      return FirebaseFirestore.instance.collection('orders').where('email', isEqualTo: widget.userEmail)
          .where('orderStatus', isEqualTo: 'previous').snapshots();
    }

    Future<DocumentSnapshot?> futurePreviousUserInfo() async {
      final userSnap = await FirebaseFirestore.instance.collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1).get();
      if(userSnap.docs.isNotEmpty){
        return userSnap.docs.first;
      }
      return null;
    }


    Stream<QuerySnapshot<Map<String, dynamic>>> previousOrders() {
      return FirebaseFirestore.instance.collection('orders').where('orderStatus', isEqualTo: 'previous').snapshots();
    }


    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: IconButton(onPressed: (){Navigator.of(context).pop();},icon: Icon(Icons.arrow_back),),
            title: Text("Your Orders"),
            backgroundColor: Colors.blue,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 14.0,left: 45,right: 45,bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recent Order",style: TextStyle(fontSize: 35,fontWeight: FontWeight.bold),),
                  SizedBox(height: 5,),

                  //Recent Order
                  SizedBox(
                    height: 530,
                    width: double.maxFinite,
                    child: Card(
                      elevation: 20,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30.0,right: 30,top: 20,bottom: 20),
                        child: StreamBuilder<QuerySnapshot>(
                                stream: streamRecentOrderDetails(),
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
                                    return Center(child: Text('No items in your recent order.'));
                                  }

                                  final orderInfo = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                                  String orderedDate = DateFormat("d MMM yyyy").format(orderInfo['orderedDate'].toDate());
                                  String shippedDate = DateFormat("d MMM yyyy").format(orderInfo['shippedDate'].toDate());
                                  String inTransitDate = DateFormat("d MMM yyyy").format(orderInfo['inTransitDate'].toDate());
                                  String outDiliveredDate = DateFormat("d MMM yyyy").format(orderInfo['outDiliveredDate'].toDate());
                                  String deliveredDate = DateFormat("d MMM yyyy").format(orderInfo['deliveredDate'].toDate());

                                  return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Order Id: ${orderInfo['orderId']}",style: TextStyle(fontSize: 21,fontWeight: FontWeight.bold),),
                                            SizedBox(width: 20,),
                                            Text("Ordered On: $orderedDate",style: TextStyle(fontSize: 17),),
                                            Spacer(),
                                            Text("Est. Delivery On: $deliveredDate",style: TextStyle(fontSize: 17,color: Colors.green),),
                                          ],
                                        ),

                                        Divider(),SizedBox(height: 8,),

                                        Expanded(
                                          child: Row(
                                            children: [

                                              //List Of Items
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Ordered Items",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                    SizedBox(height: 5,),
                                                    Expanded(
                                                      child: StreamBuilder<QuerySnapshot>(
                                                          stream: streamRecentOrderItems(),
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
                                                              return Center(child: Text('No items in your order.'));
                                                            }


                                                            final orderItems = snapshot.data!.docs;
                                                            return ListView.builder(
                                                              itemCount: orderItems.length,
                                                              itemBuilder: (context, index){

                                                                var ordItems = orderItems[index].data() as Map<String, dynamic>;

                                                                return Container(
                                                                    width: 100,
                                                                    height: 130,
                                                                    margin: EdgeInsets.all(8),
                                                                    decoration: BoxDecoration(
                                                                      // color: Colors.white,
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      border: Border.all(color: Color(0x1F000000)),
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: Colors.black.withOpacity(0.05),
                                                                          blurRadius: 2,
                                                                          offset: const Offset(0, 1),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.all(10.0),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                        children: [

                                                                          ClipRRect(
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            child: Container(
                                                                              color: Colors.white, // Ensure a white background for non-filling images
                                                                              child: AspectRatio(
                                                                                aspectRatio: 1.3,
                                                                                child: Image.network(
                                                                                  '${ordItems['imageUrl']}',
                                                                                  fit: BoxFit.cover,
                                                                                  width: 30,
                                                                                  errorBuilder: (context, error, stackTrace) =>
                                                                                  const Icon(Icons.broken_image, size: 60),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),

                                                                          SizedBox(width: 10,),

                                                                          Expanded(
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [

                                                                                Text(
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  maxLines: 2,
                                                                                  "${ordItems['productName']}",
                                                                                  style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Color(0xFF004C5E)),
                                                                                ),
                                                                                // SizedBox(height: 10,),

                                                                                Text("Quantity: ${ordItems['quantity']}",style: TextStyle(fontSize: 14),),

                                                                                Text("Price: ${ordItems['price']}"),
                                                                                Spacer(),
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Text("Total: ${ordItems['itemTotalPrice']}",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),

                                                                                    Text("${ordItems['itemStatus']}",style: TextStyle(color: Colors.green,fontSize: 15,fontWeight: FontWeight.bold),),
                                                                                  ],
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )

                                                                );
                                                              },
                                                            );
                                                          }
                                                      ),
                                                    ),


                                                  ],
                                                ),
                                              ),

                                              SizedBox(width: 20,),

                                              //Order Details & Status
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  children: [

                                                    //Shiped To, Order Summary ....
                                                    Expanded(
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(top: 30,left: 30),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [

                                                            FutureBuilder<DocumentSnapshot?>(
                                                              future: futureRecentUserInfo(),
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
                                                                if (!snapshot.hasData || snapshot.data == null) {
                                                                  return Center(child: Text('No items in your order.'));
                                                                }

                                                                final userInfo = snapshot.data!.data() as Map<String, dynamic>;

                                                                return Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Text("Delivere To -",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                                        SizedBox(width: 20,),
                                                                        Text("${userInfo['username']}",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                                      ],
                                                                    ),

                                                                    SizedBox(height: 6,),
                                                                    Text("${userInfo['street']},",style: TextStyle(fontSize: 16),),
                                                                    Text("${userInfo['area']},",style: TextStyle(fontSize: 16),),
                                                                    Text("${userInfo['city']},",style: TextStyle(fontSize: 16),),
                                                                    Text("${userInfo['state']} - ${userInfo['pincode']}",style: TextStyle(fontSize: 16),),
                                                                  ],
                                                                );
                                                              },
                                                            ),





                                                            SizedBox(height: 15,),
                                                            Divider(),
                                                            Text("Order Summary",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                            SizedBox(height: 6,),

                                                            StreamBuilder(
                                                                stream: streamRecentPaymentInfo(),
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
                                                                  if (!snapshot.hasData || snapshot.data == null) {
                                                                    return Center(child: Text('No items in your order.'));
                                                                  }

                                                                  final paymentInfo = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                                                                  return Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("Items Subtotal: ",style: TextStyle(fontSize: 16),),
                                                                          Text(" ${paymentInfo['subTotal']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("CGST: ",style: TextStyle(fontSize: 16),),
                                                                          Text(" ${paymentInfo['CGST']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("SGST: ",style: TextStyle(fontSize: 16),),
                                                                          Text(" ${paymentInfo['SGST']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("Grand Total: ",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
                                                                          Text(" ${paymentInfo['grandTotal']}",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
                                                                        ],
                                                                      ),

                                                                      SizedBox(height: 5,),
                                                                      Divider(),

                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("Payment Method: ",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                                                                          Text("${paymentInfo['paymentMethod']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  );
                                                                }
                                                            ),





                                                            SizedBox(height: 16,),

                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                ElevatedButton(
                                                                  onPressed: (){},
                                                                  style: ElevatedButton.styleFrom(
                                                                    // backgroundColor: Colors.blue,
                                                                    // foregroundColor: Colors.white
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.receipt_rounded),
                                                                      Text("Invoice")
                                                                    ],
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: (){},
                                                                  style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.redAccent,
                                                                      foregroundColor: Colors.white
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.clear_rounded),
                                                                      Text("Cancel")
                                                                    ],
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: (){},
                                                                  style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.blue,
                                                                      foregroundColor: Colors.white
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.assignment_return_outlined),
                                                                      Text("Exchange")
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),


                                                    //Straight Divider
                                                    Padding(
                                                      padding: EdgeInsets.only(left: 40,right: 30,top: 20,bottom: 20),
                                                      child: Container(
                                                        height: double.maxFinite,
                                                        width: 1.5,
                                                        decoration: BoxDecoration(
                                                          color: Color(0x1F000000),
                                                        ),
                                                      ),
                                                    ),


                                                    //Order Tracking Status
                                                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                                        stream: streamRecentOrderDetails(),
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
                                                          if (!snapshot.hasData || snapshot.data == null) {
                                                            return Center(child: Text('No items in your order.'));
                                                          }

                                                          final orderInfo = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                                                          String orderedDate = DateFormat("d MMM yyyy").format(orderInfo['orderedDate'].toDate());
                                                          String shippedDate = DateFormat("d MMM yyyy").format(orderInfo['shippedDate'].toDate());
                                                          String inTransitDate = DateFormat("d MMM yyyy").format(orderInfo['inTransitDate'].toDate());
                                                          String outDiliveredDate = DateFormat("d MMM yyyy").format(orderInfo['outDiliveredDate'].toDate());
                                                          String deliveredDate = DateFormat("d MMM yyyy").format(orderInfo['deliveredDate'].toDate());

                                                          return FutureBuilder<DocumentSnapshot?>(
                                                            future: futureRecentUserInfo(),
                                                            builder: (context, snapshot){

                                                              // 1️⃣ Check for errors
                                                              if (snapshot.hasError) {
                                                                return Center(child: Text('Error: ${snapshot.error}'));
                                                              }

                                                              // 2️⃣ Show loading indicator while waiting
                                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                                return Center(child: CircularProgressIndicator());
                                                              }

                                                              String? city;
                                                              // 3️⃣ Check if no data or empty
                                                              if (snapshot.hasData || snapshot.data!.exists) {
                                                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                                                city = userData['city'] ?? 'City';
                                                              }


                                                              // 2. Sample data matching your order's estimated progress
                                                              final List<TrackingStep> trackingSteps = [
                                                                TrackingStep('Order Confirmed', orderedDate, isCompleted: true),
                                                                TrackingStep('Shipped', shippedDate, isCompleted: true, isCurrent: true), // Current step
                                                                TrackingStep('In Transit ($city Hub)', inTransitDate),
                                                                TrackingStep('Out for Delivery', outDiliveredDate),
                                                                TrackingStep('Delivered', 'Est. $deliveredDate'),
                                                              ];
                                                              return Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [

                                                                    const Padding(
                                                                      padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                                                                      child: Text(
                                                                        '📦 Shipping Status',
                                                                        style: TextStyle(
                                                                          fontSize: 18,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: Color(0xFF333333),
                                                                        ),
                                                                      ),
                                                                    ),

                                                                    // The main timeline widget
                                                                    Padding(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                                                      child: Column(
                                                                        children: trackingSteps.asMap().entries.map((entry) {
                                                                          int index = entry.key;
                                                                          TrackingStep step = entry.value;
                                                                          bool isFirst = index == 0;
                                                                          bool isLast = index == trackingSteps.length - 1;

                                                                          return TimelineTile(
                                                                            isFirst: isFirst,
                                                                            isLast: isLast,
                                                                            alignment: TimelineAlign.start,
                                                                            indicatorStyle: IndicatorStyle(
                                                                              width: 20,
                                                                              height: 20,
                                                                              color: step.isCompleted || step.isCurrent ? const Color(0xFF5CB85C) : const Color(0xFFDDDDDD),
                                                                              iconStyle: IconStyle(
                                                                                iconData: step.isCompleted ? Icons.check : Icons.circle_outlined,
                                                                                color: Colors.white,
                                                                                fontSize: 12,
                                                                              ),
                                                                              // An optional small dot for the indicator to look cleaner
                                                                              indicator: Container(
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: step.isCompleted || step.isCurrent ? const Color(0xFF5CB85C) : const Color(0xFFDDDDDD),
                                                                                  border: step.isCurrent
                                                                                      ? Border.all(color: const Color(0x665CB85C), width: 3) // Green glow for current step
                                                                                      : null,
                                                                                ),
                                                                                child: Icon(
                                                                                  step.isCompleted ? Icons.check : Icons.circle_outlined,
                                                                                  color: Colors.white,
                                                                                  size: 12,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            beforeLineStyle: LineStyle(
                                                                              color: step.isCompleted ? const Color(0xFF5CB85C) : const Color(0xFFDDDDDD),
                                                                              thickness: 2,
                                                                            ),
                                                                            endChild: Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 10.0),
                                                                              child: Row(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    step.title,
                                                                                    style: TextStyle(
                                                                                      fontWeight: FontWeight.w600,
                                                                                      fontSize: 15,
                                                                                      color: step.isCompleted || step.isCurrent ? const Color(0xFF5CB85C) : Colors.black87,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(width: 10),
                                                                                  Text(
                                                                                    step.date,
                                                                                    style: const TextStyle(
                                                                                      fontSize: 13,
                                                                                      color: Color(0xFF888888),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ),
                                                                    ),

                                                                    const SizedBox(height: 20), // Spacing before the final buttons
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );







                                                        }
                                                    ),

                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]
                                  );
                                }
                            ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),


                  Row(
                    children: [
                      Text("Previous Orders",style: TextStyle(fontSize: 35,fontWeight: FontWeight.bold),),
                      SizedBox(width: 20,),
                      SearchBar(
                        hintText: 'Search By Date',
                      )
                    ],
                  ),

                  SizedBox(height: 5,),

                  //Previous Order
                  SizedBox(
                    height: 530,
                    width: double.maxFinite,
                    child: Card(
                      elevation: 20,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30.0,right: 30,top: 20,bottom: 20),
                        child: StreamBuilder<QuerySnapshot>(
                                stream: streamPreviousOrderDetails(),
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
                                    return Center(child: Text('No items in your previous order.'));
                                  }

                                  final orderInfo = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                                  String orderedDate = DateFormat("d MMM yyyy").format(orderInfo['orderedDate'].toDate());
                                  String shippedDate = DateFormat("d MMM yyyy").format(orderInfo['shippedDate'].toDate());
                                  String inTransitDate = DateFormat("d MMM yyyy").format(orderInfo['inTransitDate'].toDate());
                                  String outDiliveredDate = DateFormat("d MMM yyyy").format(orderInfo['outDiliveredDate'].toDate());
                                  String deliveredDate = DateFormat("d MMM yyyy").format(orderInfo['deliveredDate'].toDate());

                                  return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                  children: [
                                  Text("Order Id: ${orderInfo['orderId']}",style: TextStyle(fontSize: 21,fontWeight: FontWeight.bold),),
                                  SizedBox(width: 20,),
                                  Text("Ordered On: $orderedDate",style: TextStyle(fontSize: 17),),
                                  Spacer(),
                                  Text("Est. Delivery On: $deliveredDate",style: TextStyle(fontSize: 17,color: Colors.green),),
                                  ],
                                  ),

                                        Divider(),SizedBox(height: 8,),

                                        Expanded(
                                          child: Row(
                                            children: [

                                              //List Of Items
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Ordered Items",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                    SizedBox(height: 5,),
                                                    Expanded(
                                                      child: StreamBuilder<QuerySnapshot>(
                                                          stream: streamPreviousOrderItems(),
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
                                                              return Center(child: Text('No items in your order.'));
                                                            }


                                                            final orderItems = snapshot.data!.docs;
                                                            return ListView.builder(
                                                              itemCount: orderItems.length,
                                                              itemBuilder: (context, index){

                                                                var ordItems = orderItems[index].data() as Map<String, dynamic>;

                                                                return Container(
                                                                    width: 100,
                                                                    height: 130,
                                                                    margin: EdgeInsets.all(8),
                                                                    decoration: BoxDecoration(
                                                                      // color: Colors.white,
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      border: Border.all(color: Color(0x1F000000)),
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: Colors.black.withOpacity(0.05),
                                                                          blurRadius: 2,
                                                                          offset: const Offset(0, 1),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.all(10.0),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                        children: [

                                                                          ClipRRect(
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            child: Container(
                                                                              color: Colors.white, // Ensure a white background for non-filling images
                                                                              child: AspectRatio(
                                                                                aspectRatio: 1.3,
                                                                                child: Image.network(
                                                                                  '${ordItems['imageUrl']}',
                                                                                  fit: BoxFit.cover,
                                                                                  width: 30,
                                                                                  errorBuilder: (context, error, stackTrace) =>
                                                                                  const Icon(Icons.broken_image, size: 60),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),

                                                                          SizedBox(width: 10,),

                                                                          Expanded(
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [

                                                                                Text(
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  maxLines: 2,
                                                                                  "${ordItems['productName']}",
                                                                                  style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Color(0xFF004C5E)),
                                                                                ),
                                                                                // SizedBox(height: 10,),

                                                                                Text("Quantity: ${ordItems['quantity']}",style: TextStyle(fontSize: 14),),

                                                                                Text("Price: ${ordItems['price']}"),
                                                                                Spacer(),
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Text("Total: ${ordItems['itemTotalPrice']}",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),

                                                                                    Text("${ordItems['itemStatus']}",style: TextStyle(color: Colors.green,fontSize: 15,fontWeight: FontWeight.bold),),
                                                                                  ],
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )

                                                                );
                                                              },
                                                            );
                                                          }
                                                      ),
                                                    ),


                                                  ],
                                                ),
                                              ),

                                              SizedBox(width: 20,),

                                              //Order Details & Status
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  children: [

                                                    //Shiped To, Order Summary ....
                                                    Expanded(
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(top: 30,left: 30),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [

                                                            FutureBuilder<DocumentSnapshot?>(
                                                              future: futurePreviousUserInfo(),
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
                                                                if (!snapshot.hasData || snapshot.data == null) {
                                                                  return Center(child: Text('No items in your order.'));
                                                                }

                                                                final userInfo = snapshot.data!.data() as Map<String, dynamic>;

                                                                return Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Text("Delivere To -",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                                        SizedBox(width: 20,),
                                                                        Text("${userInfo['username']}",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                                      ],
                                                                    ),

                                                                    SizedBox(height: 6,),
                                                                    Text("${userInfo['street']},",style: TextStyle(fontSize: 16),),
                                                                    Text("${userInfo['area']},",style: TextStyle(fontSize: 16),),
                                                                    Text("${userInfo['city']},",style: TextStyle(fontSize: 16),),
                                                                    Text("${userInfo['state']} - ${userInfo['pincode']}",style: TextStyle(fontSize: 16),),
                                                                  ],
                                                                );
                                                              },
                                                            ),

                                                            SizedBox(height: 15,),
                                                            Divider(),

                                                            Text("Order Summary",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                            SizedBox(height: 6,),

                                                            StreamBuilder(
                                                                stream: streamPreviousPaymentInfo(),
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
                                                                  if (!snapshot.hasData || snapshot.data == null) {
                                                                    return Center(child: Text('No items in your order.'));
                                                                  }

                                                                  final paymentInfo = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                                                                  return Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("Items Subtotal: ",style: TextStyle(fontSize: 16),),
                                                                          Text(" ${paymentInfo['subTotal']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("CGST: ",style: TextStyle(fontSize: 16),),
                                                                          Text(" ${paymentInfo['CGST']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("SGST: ",style: TextStyle(fontSize: 16),),
                                                                          Text(" ${paymentInfo['SGST']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("Grand Total: ",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
                                                                          Text(" ${paymentInfo['grandTotal']}",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
                                                                        ],
                                                                      ),

                                                                      SizedBox(height: 5,),
                                                                      Divider(),

                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text("Payment Method: ",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                                                                          Text("${paymentInfo['paymentMethod']}",style: TextStyle(fontSize: 16),),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  );
                                                                }
                                                            ),





                                                            SizedBox(height: 16,),

                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                ElevatedButton(
                                                                  onPressed: (){},
                                                                  style: ElevatedButton.styleFrom(
                                                                    // backgroundColor: Colors.blue,
                                                                    // foregroundColor: Colors.white
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.receipt_rounded),
                                                                      Text("Invoice")
                                                                    ],
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: (){},
                                                                  style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.redAccent,
                                                                      foregroundColor: Colors.white
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.clear_rounded),
                                                                      Text("Cancel")
                                                                    ],
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: (){},
                                                                  style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.blue,
                                                                      foregroundColor: Colors.white
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.assignment_return_outlined),
                                                                      Text("Exchange")
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),


                                                    //Straight Divider
                                                    Padding(
                                                      padding: EdgeInsets.only(left: 40,right: 30,top: 20,bottom: 20),
                                                      child: Container(
                                                        height: double.maxFinite,
                                                        width: 1.5,
                                                        decoration: BoxDecoration(
                                                          color: Color(0x1F000000),
                                                        ),
                                                      ),
                                                    ),


                                                    //Order Tracking Status
                                                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                                        stream: streamPreviousOrderDetails(),
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
                                                          if (!snapshot.hasData || snapshot.data == null) {
                                                            return Center(child: Text('No items in your order.'));
                                                          }

                                                          final orderInfo = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                                                          String orderedDate = DateFormat("d MMM yyyy").format(orderInfo['orderedDate'].toDate());
                                                          String shippedDate = DateFormat("d MMM yyyy").format(orderInfo['shippedDate'].toDate());
                                                          String inTransitDate = DateFormat("d MMM yyyy").format(orderInfo['inTransitDate'].toDate());
                                                          String outDiliveredDate = DateFormat("d MMM yyyy").format(orderInfo['outDiliveredDate'].toDate());
                                                          String deliveredDate = DateFormat("d MMM yyyy").format(orderInfo['deliveredDate'].toDate());

                                                          return FutureBuilder<DocumentSnapshot?>(
                                                            future: futurePreviousUserInfo(),
                                                            builder: (context, snapshot){

                                                              // 1️⃣ Check for errors
                                                              if (snapshot.hasError) {
                                                                return Center(child: Text('Error: ${snapshot.error}'));
                                                              }

                                                              // 2️⃣ Show loading indicator while waiting
                                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                                return Center(child: CircularProgressIndicator());
                                                              }

                                                              String? city;
                                                              // 3️⃣ Check if no data or empty
                                                              if (snapshot.hasData || snapshot.data!.exists) {
                                                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                                                city = userData['city'] ?? 'City';
                                                              }


                                                              // 2. Sample data matching your order's estimated progress
                                                              final List<TrackingStep> trackingSteps = [
                                                                TrackingStep('Order Confirmed', orderedDate, isCompleted: true),
                                                                TrackingStep('Shipped', shippedDate, isCompleted: true, isCurrent: true), // Current step
                                                                TrackingStep('In Transit ($city Hub)', inTransitDate),
                                                                TrackingStep('Out for Delivery', outDiliveredDate),
                                                                TrackingStep('Delivered', 'Est. $deliveredDate'),
                                                              ];
                                                              return Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [

                                                                    const Padding(
                                                                      padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                                                                      child: Text(
                                                                        '📦 Shipping Status',
                                                                        style: TextStyle(
                                                                          fontSize: 18,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: Color(0xFF333333),
                                                                        ),
                                                                      ),
                                                                    ),

                                                                    // The main timeline widget
                                                                    Padding(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                                                      child: Column(
                                                                        children: trackingSteps.asMap().entries.map((entry) {
                                                                          int index = entry.key;
                                                                          TrackingStep step = entry.value;
                                                                          bool isFirst = index == 0;
                                                                          bool isLast = index == trackingSteps.length - 1;

                                                                          return TimelineTile(
                                                                            isFirst: isFirst,
                                                                            isLast: isLast,
                                                                            alignment: TimelineAlign.start,
                                                                            indicatorStyle: IndicatorStyle(
                                                                              width: 20,
                                                                              height: 20,
                                                                              color: step.isCompleted || step.isCurrent ? const Color(0xFF5CB85C) : const Color(0xFFDDDDDD),
                                                                              iconStyle: IconStyle(
                                                                                iconData: step.isCompleted ? Icons.check : Icons.circle_outlined,
                                                                                color: Colors.white,
                                                                                fontSize: 12,
                                                                              ),
                                                                              // An optional small dot for the indicator to look cleaner
                                                                              indicator: Container(
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: step.isCompleted || step.isCurrent ? const Color(0xFF5CB85C) : const Color(0xFFDDDDDD),
                                                                                  border: step.isCurrent
                                                                                      ? Border.all(color: const Color(0x665CB85C), width: 3) // Green glow for current step
                                                                                      : null,
                                                                                ),
                                                                                child: Icon(
                                                                                  step.isCompleted ? Icons.check : Icons.circle_outlined,
                                                                                  color: Colors.white,
                                                                                  size: 12,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            beforeLineStyle: LineStyle(
                                                                              color: step.isCompleted ? const Color(0xFF5CB85C) : const Color(0xFFDDDDDD),
                                                                              thickness: 2,
                                                                            ),
                                                                            endChild: Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 10.0),
                                                                              child: Row(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    step.title,
                                                                                    style: TextStyle(
                                                                                      fontWeight: FontWeight.w600,
                                                                                      fontSize: 15,
                                                                                      color: step.isCompleted || step.isCurrent ? const Color(0xFF5CB85C) : Colors.black87,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(width: 10),
                                                                                  Text(
                                                                                    step.date,
                                                                                    style: const TextStyle(
                                                                                      fontSize: 13,
                                                                                      color: Color(0xFF888888),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ),
                                                                    ),

                                                                    const SizedBox(height: 20), // Spacing before the final buttons
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );







                                                        }
                                                    ),

                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]
                                  );
                                }
                            ),
                      ),
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





  //SizedBox(
  //                 height: 350,
  //                 width: 600,
  //                 child: StreamBuilder(
  //                     stream: streamOrderItems(),
  //                     builder: (context, snapshot){
  //                       // 1️⃣ Check for errors
  //                       if (snapshot.hasError) {
  //                         return Center(child: Text('Error: ${snapshot.error}'));
  //                       }
  //
  //                       // 2️⃣ Show loading indicator while waiting
  //                       if (snapshot.connectionState == ConnectionState.waiting) {
  //                         return Center(child: CircularProgressIndicator());
  //                       }
  //
  //                       // 3️⃣ Check if no data or empty
  //                       if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
  //                         return Center(child: Text('No items in your order.'));
  //                       }
  //
  //
  //                       final orderItems = snapshot.data!.docs;
  //                       return ListView.builder(
  //                         itemCount: orderItems.length,
  //                         itemBuilder: (context, index){
  //
  //                           var itemS = orderItems[index].data() as Map<String, dynamic>;
  //
  //                           return Container(
  //                             width: 150,
  //                             height: 130,
  //                             margin: EdgeInsets.all(8),
  //                               decoration: BoxDecoration(
  //                                 color: Colors.white,
  //                                 borderRadius: BorderRadius.circular(0),
  //                                 border: Border.all(color: Colors.black),
  //                                 boxShadow: [
  //                                   BoxShadow(
  //                                     color: Colors.black.withOpacity(0.05),
  //                                     blurRadius: 2,
  //                                     offset: const Offset(0, 1),
  //                                   ),
  //                                 ],
  //                               ),
  //                             child: Padding(
  //                                   padding: const EdgeInsets.all(10.0),
  //                                   child: Row(
  //                                     mainAxisAlignment: MainAxisAlignment.start,
  //                                     children: [
  //
  //                                       ClipRRect(
  //                                         borderRadius: BorderRadius.circular(8),
  //                                         child: Container(
  //                                           color: Colors.white, // Ensure a white background for non-filling images
  //                                           child: AspectRatio(
  //                                             aspectRatio: 1.3,
  //                                             child: Image.network(
  //                                               '${itemS['imageUrl']}',
  //                                               fit: BoxFit.cover,
  //                                               width: 30,
  //                                               errorBuilder: (context, error, stackTrace) =>
  //                                               const Icon(Icons.broken_image, size: 60),
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //
  //                                       SizedBox(width: 10,),
  //
  //                                       Expanded(
  //                                         child: Column(
  //                                           crossAxisAlignment: CrossAxisAlignment.start,
  //                                           children: [
  //                                             Padding(
  //                                               padding: const EdgeInsets.only(top: 3.0),
  //                                               child: Row(
  //                                                 children: [
  //                                                   Text("View order details"),
  //                                                   Padding(
  //                                                     padding: const EdgeInsets.only(left: 8.0,right: 8),
  //                                                     child: Container(
  //                                                       width: 1,
  //                                                       height: 17,
  //                                                       color: Colors.black45, // subtle divider
  //                                                     ),
  //                                                   ),
  //                                                   Text("Ordered on 2 July 2025",style: TextStyle(fontSize: 14),),
  //                                                 ],
  //                                               ),
  //                                             ),
  //
  //                                             SizedBox(height: 5,),
  //                                             Text(
  //                                               overflow: TextOverflow.ellipsis,
  //                                               maxLines: 1,
  //                                               "${itemS['productName']}",
  //                                               style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Color(0xFF004C5E)),
  //                                             ),
  //                                             // SizedBox(height: 10,),
  //
  //                                             Text("Quantity: ${itemS['quantity']}",style: TextStyle(fontSize: 14),),
  //
  //                                             Text("Estimated Delivery: 10 July 2025",style: TextStyle(fontSize: 14),),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 )
  //
  //                           );
  //                         },
  //                       );
  //                     }
  //                   ),
  //
  //               ),
  //
  //               Container(
  //                 width: 700,
  //                 height: 190,
  //                 margin: EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(color: Colors.black),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withOpacity(0.05),
  //                       blurRadius: 2,
  //                       offset: const Offset(0, 1),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Padding(
  //                   padding: const EdgeInsets.only(left: 20.0,right: 20,top: 20,bottom: 10),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text("Ship To",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
  //                           SizedBox(height: 6,),
  //                           Text("Piyush Parekh",style: TextStyle(fontSize: 16),),
  //                           Text("Mandir Wali Pole,",style: TextStyle(fontSize: 16),),
  //                           Text("Santh Bazar,",style: TextStyle(fontSize: 16),),
  //                           Text("Nadiad, ",style: TextStyle(fontSize: 16),),
  //                           Text("GUJARAT 387001",style: TextStyle(fontSize: 16),),
  //                         ],
  //                       ),
  //
  //                       Padding(
  //                         padding: const EdgeInsets.only(left: 20.0,right: 20,top: 20,bottom: 20),
  //                         child: Container(
  //                           width: 1,
  //                           height: double.maxFinite,
  //                           color: Colors.black45, // subtle divider
  //                         ),
  //                       ),
  //
  //                       //Payment Method
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text("Payment Method",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
  //                           SizedBox(height: 6,),
  //                           Text("Visa Card",style: TextStyle(fontSize: 16),),
  //                         ],
  //                       ),
  //
  //                       Padding(
  //                         padding: const EdgeInsets.only(left: 20.0,right: 20,top: 20,bottom: 20),
  //                         child: Container(
  //                           width: 1,
  //                           height: double.maxFinite,
  //                           color: Colors.black45, // subtle divider
  //                         ),
  //                       ),
  //
  //                       //Total Summary
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text("Order Summary",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
  //                           SizedBox(height: 6,),
  //                           Text("Items Subtotal: 0000000",style: TextStyle(fontSize: 16),),
  //                           Text("CGST: 0000",style: TextStyle(fontSize: 16),),
  //                           Text("SGST: 0000",style: TextStyle(fontSize: 16),),
  //                           Text("Grand Total: 0000000",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
  //                         ],
  //                       ),
  //
  //                     ],
  //                   ),
  //                 ),
  //               ),














  //import 'package:flutter/material.dart';
  //
  // // --- 1. Main Method to Run the App ---
  // void main() {
  //   // Use const MyApp() since it is a StatelessWidget and does not change.
  //   runApp(const MyApp());
  // }
  //
  // // --- 2. Data Model (Enums & Class) ---
  // enum OrderStatus { Confirmed, Processing, Shipped, Delivered, Canceled }
  //
  // class Order {
  //   final String orderId;
  //   final String productName;
  //   final String productImageUrl;
  //   final DateTime orderDate;
  //   final double orderTotal;
  //   final OrderStatus status;
  //   final DateTime? estimatedDelivery;
  //   final String shippingAddress;
  //   final Map<String, double> financialBreakdown;
  //   final bool isReturnable;
  //
  //   Order({
  //     required this.orderId,
  //     required this.productName,
  //     required this.productImageUrl,
  //     required this.orderDate,
  //     required this.orderTotal,
  //     required this.status,
  //     this.estimatedDelivery,
  //     required this.shippingAddress,
  //     required this.financialBreakdown,
  //     this.isReturnable = true,
  //   });
  //
  //   String get statusDisplay => status.toString().split('.').last;
  // }
  //
  // // --- 3. The MyApp Wrapper (StatelessWidget for MaterialApp) ---
  // // This is necessary to wrap the app with theme/routing.
  // class MyApp extends StatelessWidget {
  //   const MyApp({super.key});
  //
  //   @override
  //   Widget build(BuildContext context) {
  //     return MaterialApp(
  //       title: 'Order Tracking',
  //       theme: ThemeData(
  //         primarySwatch: Colors.indigo,
  //         useMaterial3: true,
  //         appBarTheme: const AppBarTheme(
  //           elevation: 0,
  //         ),
  //       ),
  //       // The home screen is the single main Stateful Widget
  //       home: const OrderPage(),
  //     );
  //   }
  // }
  //
  // // --- 4. The Single Primary Stateful Widget (The entire screen logic) ---
  // class OrderPage extends StatefulWidget {
  //   const OrderPage({super.key});
  //
  //   @override
  //   State<OrderPage> createState() => _OrderPageState();
  // }
  //
  // // --- 5. The State Class containing ALL UI and Helper Methods ---
  // class _OrderPageState extends State<OrderPage> {
  //   // Mock Data List
  //   final List<Order> mockOrders = [
  //     Order(
  //       orderId: 'ORD009876',
  //       productName: 'Motrex Men\'s Full Sleeve Jacket',
  //       productImageUrl: 'https://via.placeholder.com/150/0000FF/808080?text=Jacket',
  //       orderDate: DateTime(2025, 7, 2),
  //       orderTotal: 43000.00,
  //       status: OrderStatus.Shipped,
  //       estimatedDelivery: DateTime(2025, 7, 10),
  //       shippingAddress: '123, Main Street, Nadiad, Gujarat - 387001',
  //       financialBreakdown: {'Subtotal': 42000.0, 'Shipping': 500.0, 'Tax': 500.0},
  //     ),
  //     Order(
  //       orderId: 'ORD009875',
  //       productName: 'Pro Wireless Headphones',
  //       productImageUrl: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=Headphones',
  //       orderDate: DateTime(2025, 6, 25),
  //       orderTotal: 12500.00,
  //       status: OrderStatus.Delivered,
  //       estimatedDelivery: DateTime(2025, 6, 28),
  //       shippingAddress: '456, Gandhi Road, Anand, Gujarat - 388001',
  //       financialBreakdown: {'Subtotal': 12000.0, 'Shipping': 500.0},
  //     ),
  //     Order(
  //       orderId: 'ORD009874',
  //       productName: 'Ergonomic Office Chair',
  //       productImageUrl: 'https://via.placeholder.com/150/008000/FFFFFF?text=Chair',
  //       orderDate: DateTime(2025, 5, 10),
  //       orderTotal: 25000.00,
  //       status: OrderStatus.Confirmed,
  //       shippingAddress: '789, New Area, Vadodara, Gujarat - 390001',
  //       financialBreakdown: {'Subtotal': 24500.0, 'Shipping': 500.0},
  //     ),
  //   ];
  //
  //   // Helper for Status Color (Used in multiple places)
  //   Color _getStatusColor(OrderStatus status) {
  //     switch (status) {
  //       case OrderStatus.Delivered: return Colors.green.shade700;
  //       case OrderStatus.Shipped: return Colors.blue.shade700;
  //       case OrderStatus.Processing:
  //       case OrderStatus.Confirmed: return Colors.orange.shade700;
  //       case OrderStatus.Canceled: return Colors.red.shade700;
  //     }
  //   }
  //
  //   // --- UI Helper Methods (Replacing separate Widget Classes) ---
  //
  //   Widget _buildSectionHeader(String title) {
  //     return Padding(
  //       padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
  //       child: Text(
  //         title,
  //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
  //       ),
  //     );
  //   }
  //
  //   Widget _buildProductItem(Order order) {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 4.0),
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           ClipRRect(
  //             borderRadius: BorderRadius.circular(8.0),
  //             child: Image.network(order.productImageUrl, width: 70, height: 70, fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) => Container(
  //                   width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey)),
  //             ),
  //           ),
  //           const SizedBox(width: 15),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  //                 const Text('Quantity: 1', style: TextStyle(color: Colors.grey)),
  //               ],
  //             ),
  //           ),
  //           Text(
  //               '₹${order.orderTotal.toStringAsFixed(2)}',
  //               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //         ],
  //       ),
  //     );
  //   }
  //
  //   Widget _buildFinancialRow(String label, double amount, {bool isTotal = false}) {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 2.0),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //               label,
  //               style: TextStyle(
  //                 fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
  //                 fontSize: isTotal ? 15 : 14,
  //                 color: isTotal ? Colors.black : Colors.grey.shade800,
  //               )),
  //           Text(
  //               '₹${amount.toStringAsFixed(2)}',
  //               style: TextStyle(
  //                 fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
  //                 fontSize: isTotal ? 15 : 14,
  //                 color: isTotal ? Colors.black : Colors.grey.shade800,
  //               )),
  //         ],
  //       ),
  //     );
  //   }
  //
  //   Widget _buildShippingDetails(Order order) {
  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text('Shipping Address:', style: TextStyle(fontWeight: FontWeight.bold)),
  //         Text(order.shippingAddress),
  //         const SizedBox(height: 10),
  //         if (order.estimatedDelivery != null && order.status != OrderStatus.Delivered)
  //           Text('Est. Delivery: ${order.estimatedDelivery!.day}/${order.estimatedDelivery!.month}/${order.estimatedDelivery!.year}',
  //               style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
  //         if (order.status == OrderStatus.Delivered)
  //           const Text('Delivered successfully.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
  //       ],
  //     );
  //   }
  //
  //   Widget _buildActionButtons(Order order) {
  //     return Padding(
  //       padding: const EdgeInsets.only(top: 15.0),
  //       child: Wrap(
  //         spacing: 10.0,
  //         runSpacing: 10.0,
  //         alignment: WrapAlignment.start,
  //         children: [
  //           // Download Invoice / Receipt
  //           ElevatedButton.icon(
  //             onPressed: () { /* Handle download */ },
  //             icon: const Icon(Icons.download, size: 18),
  //             label: const Text('Invoice'),
  //           ),
  //
  //           // Cancel Order (Dynamic)
  //           if (order.status == OrderStatus.Confirmed || order.status == OrderStatus.Processing)
  //             ElevatedButton.icon(
  //               onPressed: () { /* Handle cancellation */ },
  //               icon: const Icon(Icons.cancel, size: 18),
  //               label: const Text('Cancel'),
  //               style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
  //             ),
  //
  //           // Request Return / Exchange (Dynamic)
  //           if (order.status == OrderStatus.Delivered && order.isReturnable)
  //             OutlinedButton.icon(
  //               onPressed: () { /* Handle return request */ },
  //               icon: const Icon(Icons.undo, size: 18),
  //               label: const Text('Return/Exchange'),
  //             ),
  //
  //           // Reorder Item(s) (Dynamic)
  //           if (order.status == OrderStatus.Delivered)
  //             OutlinedButton.icon(
  //               onPressed: () { /* Handle reorder */ },
  //               icon: const Icon(Icons.refresh, size: 18),
  //               label: const Text('Reorder'),
  //             ),
  //
  //           // Contact Support (Always visible)
  //           TextButton.icon(
  //             onPressed: () { /* Handle support contact */ },
  //             icon: const Icon(Icons.support_agent, size: 18),
  //             label: const Text('Support'),
  //             style: TextButton.styleFrom(foregroundColor: Colors.indigo),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //
  //   Widget _buildExpandedOrderCard(Order order) {
  //     return Card(
  //       elevation: 2,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       margin: const EdgeInsets.only(bottom: 24.0),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // --- A. Header: Status, Order ID, Date ---
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
  //                     const SizedBox(height: 4),
  //                     Text('Ordered: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
  //                         style: const TextStyle(fontSize: 13, color: Colors.grey)),
  //                   ],
  //                 ),
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //                   decoration: BoxDecoration(
  //                     color: _getStatusColor(order.status).withOpacity(0.15),
  //                     borderRadius: BorderRadius.circular(20),
  //                   ),
  //                   child: Text(order.statusDisplay,
  //                       style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 14)),
  //                 ),
  //               ],
  //             ),
  //             const Divider(height: 25, thickness: 1),
  //
  //             // --- B. Product/Summary ---
  //             _buildProductItem(order),
  //             const Divider(height: 25, thickness: 1),
  //
  //             // --- C. Financial Breakdown ---
  //             _buildSectionHeader('Financial Breakdown'),
  //             Column(
  //               children: [
  //                 ...order.financialBreakdown.entries.map((e) => _buildFinancialRow(e.key, e.value)),
  //                 const Divider(height: 10, thickness: 1.5),
  //                 _buildFinancialRow('GRAND TOTAL', order.orderTotal, isTotal: true),
  //               ],
  //             ),
  //             const SizedBox(height: 5),
  //
  //             // --- D. Shipping Details ---
  //             _buildSectionHeader('Shipping Details'),
  //             _buildShippingDetails(order),
  //
  //             // --- E. Action Buttons ---
  //             _buildActionButtons(order),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //
  //   // --- Main Build Method for the OrderPage ---
  //   @override
  //   Widget build(BuildContext context) {
  //     return Scaffold(
  //       appBar: AppBar(
  //         title: const Text('Your Orders (All Details)'),
  //         centerTitle: false,
  //       ),
  //       body: ListView.builder(
  //         padding: const EdgeInsets.all(16.0),
  //         itemCount: mockOrders.length,
  //         itemBuilder: (context, index) {
  //           // Builds the complete card for each order
  //           return _buildExpandedOrderCard(mockOrders[index]);
  //         },
  //       ),
  //     );
  //   }
  // }