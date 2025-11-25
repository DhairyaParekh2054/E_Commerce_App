import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';
import 'package:intl/intl.dart';

Future<void> main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminOrders());

}


class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> with SingleTickerProviderStateMixin{

  late TabController _tabController;
  int? _pendingOrders;
  int? _inTransitsOrder;
  int? _deliveredOrder;
  int? _exchangedOrder;
  int? _canceledOrder;

  Future<void> count() async{
    try{
      QuerySnapshot countPending = await FirebaseFirestore.instance.collection("orders").where('shippingStatus', isEqualTo: 'Order Confirmed').get();
      int countedPedingOrd = countPending.docs.length;

      QuerySnapshot countInTransits = await FirebaseFirestore.instance.collection("orders").where('shippingStatus', isEqualTo: 'In Transits').get();
      int countedInTransitsOrd = countInTransits.docs.length;

      QuerySnapshot countDelivered = await FirebaseFirestore.instance.collection("orders").where('shippingStatus', isEqualTo: 'Delivered').get();
      int countedDeliveredOrd = countDelivered.docs.length;

      QuerySnapshot countExchanged = await FirebaseFirestore.instance.collection("orders").where('shippingStatus', isEqualTo: 'Exchanged').get();
      int countedExchangedOrd = countExchanged.docs.length;

      QuerySnapshot countCanceled = await FirebaseFirestore.instance.collection("orders").where('shippingStatus', isEqualTo: 'Canceled').get();
      int countedCanceledOrd = countCanceled.docs.length;


      if(mounted){
        setState(() {
          _pendingOrders = countedPedingOrd;
          _inTransitsOrder = countedInTransitsOrd;
          _deliveredOrder = countedDeliveredOrd;
          _exchangedOrder = countedExchangedOrd;
          _canceledOrder = countedCanceledOrd;
        });
      }
    }catch(e){

      if(mounted){
        setState(() {
          _pendingOrders = 0;
          _inTransitsOrder = 0;
          _deliveredOrder = 0;
          _exchangedOrder = 0;
          _canceledOrder = 0;
        });
      }
    }

  }


  @override
  void initState() {
    super.initState();
    count();
    _tabController = TabController(length: 5, vsync: this); // 3 tabs
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    count();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Manage Orders",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 40),),
                SizedBox(height: 40,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 60,
                      width: 900,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black12,
                            width: 1
                          )
                        ),
                        child: TabBar(
                          controller: _tabController,
                          unselectedLabelColor: Colors.black26,
                          tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.update,color: Colors.deepPurple),
                                SizedBox(width: 5,),
                                Text("Pending($_pendingOrders)",style: TextStyle(color: Colors.deepPurple)),
                              ],
                            ),
                          ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.emoji_transportation_rounded,color: Colors.orange),
                                  SizedBox(width: 5,),
                                  Text("InTransit($_inTransitsOrder)",style: TextStyle(color: Colors.orange)),
                                ],
                              ),
                            ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_box_rounded,color: Colors.green),
                                SizedBox(width: 5,),
                                Text("Delivered($_deliveredOrder)",style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.published_with_changes_rounded,color: Colors.blue),
                                  SizedBox(width: 5,),
                                  Text("Exchanged($_exchangedOrder)",style: TextStyle(color: Colors.blue)), //Exchanged ,
                                ],
                              ),
                            ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel,color: Colors.red),
                                SizedBox(width: 5,),
                                Text("Canceled($_canceledOrder)",style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],),
                      ),
                    ),
                  ],
                ),
      
                Padding(
                  padding: const EdgeInsets.only(top: 14,bottom: 14),
                  child: Divider(),
                ),
      
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      PendingOrder(),
                      InTransitsOrders(),
                      DeliveredOrders(),
                      ExchangedOrders(),
                      CanceledOrders(),
                    ],
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



class PendingOrder extends StatefulWidget {
  const PendingOrder({super.key});

  @override
  State<PendingOrder> createState() => _PendingOrderState();
}
class _PendingOrderState extends State<PendingOrder> {

  Stream<QuerySnapshot> pendingOrder() {
    return FirebaseFirestore.instance.collection('orders').where('shippingStatus', isEqualTo: 'Order Confirmed').snapshots();
  }

  Future<void> setInTransits(String orderId) async{
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'shippingStatus': 'In Transits'
    });
  }

  int itemCount=5;

  // Future<void> count() async{}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: pendingOrder(),
      builder: (context, snapshot) {
        var count = 0;
        if(snapshot.data!=null){
          count=snapshot.data!.docs.length;
        }
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No Order Pending'));
        }

        return ListView.builder(
          itemCount: count,
          itemBuilder: (context, index){

            DocumentSnapshot penOrder = snapshot.data!.docs[index];
            String orderedDate = DateFormat("d MMM yyyy").format(penOrder['orderedDate'].toDate());

          return ListTile(
            leading: Text("Items: $itemCount",style: TextStyle(fontSize: 20),),
            title: Row(
              children: [
                Text("Order Id: ${penOrder['orderId']}"),
                SizedBox(width: 20,),
                Text("Customer Email: ${penOrder['email']}"),
              ],
            ),
            subtitle: Text("Ordered Date: $orderedDate"),
            trailing: ElevatedButton(
              onPressed: (){
                setInTransits(penOrder['orderId']);
              },
              child: Text("Set as InTransits",style: TextStyle(fontWeight: FontWeight.bold),),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.0)
                ),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white
              ),
            ),
          );
        });
      }
    );
  }
}


class InTransitsOrders extends StatefulWidget {
  const InTransitsOrders({super.key});

  @override
  State<InTransitsOrders> createState() => _InTransitsOrdersState();
}
class _InTransitsOrdersState extends State<InTransitsOrders> {

  Stream<QuerySnapshot> inTransitsOrder() {
    return FirebaseFirestore.instance.collection('orders').where('shippingStatus', isEqualTo: 'In Transits').snapshots();
  }

  Future<void> setDelivered(String orderId) async{
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'shippingStatus': 'Delivered'
    });
  }


  List<Map<String, String>> userCityList = [];

  Future<void> loadcity() async{

    try{
      final orders = await FirebaseFirestore.instance.collection('orders').where('shippingStatus', isEqualTo: 'Delivered').get();

      if(orders.docs.isEmpty){
        return;
      }


      userCityList.clear();

      for (var orderDoc in orders.docs) {
        String email = orderDoc['email'];

        // 3️⃣ Get city from users collection using email
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        String city = "Unknown";
        if (userSnapshot.docs.isNotEmpty) {
          city = userSnapshot.docs.first['city'] ?? "Unknown";
        }

        // 4️⃣ Add combined result to list
        userCityList.add({
          "email": email,
          "city": city,
        });
      }


      setState(() {});

    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Null")),
      );
    }
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadcity();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: inTransitsOrder(),
        builder: (context, snapshot) {
          var count = 0;
          if(snapshot.data!=null){
            count=snapshot.data!.docs.length;
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Order In Transits'));
          }


          return ListView.builder(
              itemCount: count,
              itemBuilder: (context, index){

                DocumentSnapshot penOrder = snapshot.data!.docs[index];
                String orderedDate = DateFormat("d MMM yyyy").format(penOrder['orderedDate'].toDate());

                final data = userCityList[index];

                return ListTile(
                  leading: Text("Items: 5",style: TextStyle(fontSize: 20),),
                  title: Row(
                    children: [
                      Text("Order Id: ${penOrder['orderId']}"),
                      SizedBox(width: 20,),
                      Text("Customer Email: ${penOrder['email']}"),

                      SizedBox(width: 20,),
                      Text("Hub City: ${data['city']}"),
                    ],
                  ),
                  subtitle: Text("Ordered Date: $orderedDate"),
                  trailing: ElevatedButton(
                    onPressed: (){
                      setDelivered(penOrder['orderId']);
                    },
                    child: Text("Set as Delivered",style: TextStyle(fontWeight: FontWeight.bold),),
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0.0)
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white
                    ),
                  ),
                );
              });
        }
    );
  }
}


class DeliveredOrders extends StatefulWidget {
  const DeliveredOrders({super.key});

  @override
  State<DeliveredOrders> createState() => _DeliveredOrdersState();
}
class _DeliveredOrdersState extends State<DeliveredOrders> {

  Stream<QuerySnapshot> deliveredOrder() {
    return FirebaseFirestore.instance.collection('orders').where('shippingStatus', isEqualTo: 'Delivered').snapshots();
  }

  List<Map<String, String>> userCityList = [];
  List<Map<String, String>> userStateList = [];

  Future<void> loadcity() async{

    try{
      final orders = await FirebaseFirestore.instance.collection('orders').where('shippingStatus', isEqualTo: 'Delivered').get();

      if(orders.docs.isEmpty){
        return;
      }


      userCityList.clear();
      userStateList.clear();

      for (var orderDoc in orders.docs) {
        String email = orderDoc['email'];

        // 3️⃣ Get city from users collection using email
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        String city = "Unknown";
        String state = "Unknown";
        if (userSnapshot.docs.isNotEmpty) {
          city = userSnapshot.docs.first['city'] ?? "Unknown";
          state = userSnapshot.docs.first['state'] ?? "Unknown";
        }

        // 4️⃣ Add combined result to list
        userCityList.add({
          "email": email,
          "city": city,
        });

        userStateList.add({
          "email": email,
          "state": state,
        });
      }


      setState(() {});

    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Null")),
      );
    }
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadcity();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: deliveredOrder(),
        builder: (context, snapshot) {
          var count = 0;
          if(snapshot.data!=null){
            count=snapshot.data!.docs.length;
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Order Delivered'));
          }


          return ListView.builder(
              itemCount: count,
              itemBuilder: (context, index){

                DocumentSnapshot penOrder = snapshot.data!.docs[index];
                String orderedDate = DateFormat("d MMM yyyy").format(penOrder['orderedDate'].toDate());

                final data = userCityList[index];
                final stateData = userStateList[index];

                return ListTile(
                  leading: Text("Items: 5",style: TextStyle(fontSize: 20),),
                  title: Row(
                    children: [
                      Text("Order Id: ${penOrder['orderId']}"),
                      SizedBox(width: 20,),
                      Text("Customer Email: ${penOrder['email']}"),
                    ],
                  ),
                  selectedColor: Colors.greenAccent,
                  subtitle: Text("Ordered Date: $orderedDate"),
                  trailing: Text("Delivered at ${data['city']}, ${stateData['state']}",style: TextStyle(fontSize: 20,color: Colors.green,fontWeight: FontWeight.bold),),
                );
              });
        }
    );
  }
}


class ExchangedOrders extends StatefulWidget {
  const ExchangedOrders({super.key});

  @override
  State<ExchangedOrders> createState() => _ExchangedOrdersState();
}
class _ExchangedOrdersState extends State<ExchangedOrders> {

  Stream<QuerySnapshot> exchangedOrder() {
    return FirebaseFirestore.instance.collection('orders').where('shippingStatus', isEqualTo: 'Exchanged').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: exchangedOrder(),
        builder: (context, snapshot) {
          var count = 0;
          if(snapshot.data!=null){
            count=snapshot.data!.docs.length;
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Order Exchanged'));
          }


          return ListView.builder(
              itemCount: count,
              itemBuilder: (context, index){

                DocumentSnapshot penOrder = snapshot.data!.docs[index];
                String orderedDate = DateFormat("d MMM yyyy").format(penOrder['orderedDate'].toDate());

                return ListTile(
                  leading: Text("Items: 5",style: TextStyle(fontSize: 20),),
                  title: Row(
                    children: [
                      Text("Order Id: ${penOrder['orderId']}"),
                      SizedBox(width: 20,),
                      Text("Customer Email: ${penOrder['email']}"),
                    ],
                  ),
                  subtitle: Text("Ordered Date: $orderedDate"),
                );
              });
        }
    );
  }
}


class CanceledOrders extends StatefulWidget {
  const CanceledOrders({super.key});

  @override
  State<CanceledOrders> createState() => _CanceledOrdersState();
}
class _CanceledOrdersState extends State<CanceledOrders> {

  Stream<QuerySnapshot> canceledOrder() {
    return FirebaseFirestore.instance.collection('orders').where('shippingStatus', isEqualTo: 'Canceled').snapshots();
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: canceledOrder(),
        builder: (context, snapshot) {
          var count = 0;
          if(snapshot.data!=null){
            count=snapshot.data!.docs.length;
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Order Canceled'));
          }


          return ListView.builder(
              itemCount: count,
              itemBuilder: (context, index){

                DocumentSnapshot penOrder = snapshot.data!.docs[index];
                String orderedDate = DateFormat("d MMM yyyy").format(penOrder['orderedDate'].toDate());

                return ListTile(
                  leading: Text("Items: 5",style: TextStyle(fontSize: 20),),
                  title: Row(
                    children: [
                      Text("Order Id: ${penOrder['orderId']}"),
                      SizedBox(width: 20,),
                      Text("Customer Email: ${penOrder['email']}"),
                    ],
                  ),
                  subtitle: Text("Ordered Date: $orderedDate"),
                );
              });
        }
    );
  }
}



