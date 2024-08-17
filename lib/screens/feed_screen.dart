import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('datePublished', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: mobileBackgroundColor,
                // child: CircularProgressIndicator(
                //   color: Color.fromARGB(255, 48, 47, 47),
                // ),
              );
            }
      
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No posts available'),
              );
            }
      
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: false,
                  floating: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SvgPicture.asset(
                            'assets/images/ic_instagram.svg',
                            color: primaryColor,
                            
                          ),
                        ),

                        


                      ],
                    ),
                    background: Container(
                      color: mobileBackgroundColor,
                    ),
                  ),
                  backgroundColor: mobileBackgroundColor,
                  toolbarHeight: 70
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                      child: PostCard(
                        snap: snapshot.data!.docs[index].data(),
                      ),
                    ),
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
