import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';

class UserService{
  final CollectionReference collection = FirebaseFirestore.instance.collection('users');

  Future<String?> getDocId(String email) async{
    final loadUser = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
    if(loadUser.docs.isNotEmpty){
      return loadUser.docs.first.id;
    }else{
      return null;
    }
  }

}

final UserService services = UserService();

class AdminUsers extends StatefulWidget {
  final String email;
  const AdminUsers({super.key, required this.email});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> with SingleTickerProviderStateMixin{

  late TabController _tabController;
  final _makeAdminController = TextEditingController();



  Future<void> makeAdmin() async{
    String? docId = await services.getDocId(_makeAdminController.text);
    if(docId != null){
      await services.collection.doc(docId).update({'role': 'Admin'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_makeAdminController.text} is Admin Now')),
      );

      _makeAdminController.clear();
    }

  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Manage Users",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 40),),
              SizedBox(height: 40,),
              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Row(
                  children: [
                    SizedBox(
                      height: 40,
                      width: 260,
                      child: TextField(
                        controller: _makeAdminController,
                        decoration: InputDecoration(
                          label: Text('Enter User Email'),
                          border: OutlineInputBorder()
                        ),
                      )
                    ),
                    SizedBox(width: 20,),
                    ElevatedButton(onPressed: makeAdmin, child: Text("Make As Admin"))
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 14,bottom: 14),
                child: Divider(),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 60,
                      width: 300,
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
                          labelColor: Colors.deepPurple,
                          unselectedLabelColor: Colors.black26,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person),
                                  SizedBox(width: 5,),
                                  Text("Users"),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.admin_panel_settings),
                                  SizedBox(width: 5,),
                                  Text("Admins"),
                                ],
                              ),
                            ),
                          ],),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListUsers(),
                    ListAdmins(email: widget.email)
                  ],
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}




class ListUsers extends StatefulWidget {
  const ListUsers({super.key});

  @override
  State<ListUsers> createState() => _ListUsersState();
}

class _ListUsersState extends State<ListUsers> {

  Stream<QuerySnapshot> listUser() {
    return FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'User').snapshots();
  }



  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: listUser(),
      builder: (context, snapshot){
        var count = 0;
        if(snapshot.data!=null){
          count=snapshot.data!.docs.length;
        }

        return ListView.builder(
          itemCount: count,
          itemBuilder: (context, index){

            DocumentSnapshot users = snapshot.data!.docs[index];
            return ListTile(
              leading: CircleAvatar(),
              title: Text("${users['username']}"),
              subtitle: Text("${users['email']}"),
            );
          }
        );
      },
    );
  }
}




class ListAdmins extends StatefulWidget {
  final String email;
  const ListAdmins({super.key, required this.email});

  @override
  State<ListAdmins> createState() => _ListAdminsState();
}

class _ListAdminsState extends State<ListAdmins> {

  Stream<QuerySnapshot> listAdmins() {
    return FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Admin').snapshots();
  }






  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: listAdmins(),
      builder: (context, snapshot){
        var count = 0;
        if(snapshot.data!=null){
          count=snapshot.data!.docs.length;
        }

        return ListView.builder(
            itemCount: count,
            itemBuilder: (context, index){

              DocumentSnapshot admin = snapshot.data!.docs[index];
              final userEmail = admin['email'];


              return ListTile(
                leading: CircleAvatar(),
                title: Text("${admin['username']}"),
                subtitle: Text("${admin['email']}"),
                trailing: userEmail == widget.email ?
                    Text("Current Admin",style: TextStyle(color: Colors.green,fontSize: 20),)
                : ElevatedButton(
                  onPressed: (){
                    setState(() async{
                        String? docId = await services.getDocId(userEmail);
                        if(docId != null){
                          await services.collection.doc(docId).update({'role': 'User'});

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${userEmail} Has Been Removed from Admin')),
                          );

                        }

                    });
                  },
                  child: Text("Remove Admin"),
                ),
              );
            }
        );
      }
    );
  }
}

