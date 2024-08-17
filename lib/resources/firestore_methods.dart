import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteDuplicatePhotos() async {
  try {
    // Initialize Firestore and Firebase Storage
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch all posts
    QuerySnapshot allPostsSnapshot = await firestore.collection('posts').get();

    // Map to store image hashes
    Map<String, String> imageHashes = {};
    Map<String, String> imageUrlsToDelete = {};

    // Iterate through each document
    for (QueryDocumentSnapshot doc in allPostsSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String photoUrl = data['postUrl'];

      // Download image
      Uint8List imageData = await downloadImage(photoUrl);
      String hash = computeImageHash(imageData);

      // Check for duplicates
      if (imageHashes.containsKey(hash)) {
        // Mark the URL for deletion
        imageUrlsToDelete[photoUrl] = doc.id;
      } else {
        imageHashes[hash] = photoUrl;
      }
    }

    for (String url in imageUrlsToDelete.keys) {
      await firestore.collection('posts').where('postUrl', isEqualTo: url).get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    }
    print('Cleanup completed. Duplicates have been removed.');
  } catch (e) {
    print('An error occurred while cleaning up duplicates: $e');
  }
}

Future<Uint8List> downloadImage(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to download image');
  }
}

String computeImageHash(Uint8List data) {
  var digest = sha256.convert(data);
  return digest.toString();
}


  Future<void> cleanUpDuplicatePosts() async {
  try {
    // Fetch all posts from the 'posts' collection
    QuerySnapshot allPostsSnapshot = await _firestore.collection('posts').get();

    // A map to keep track of seen descriptions
    Map<String, String> seenDescriptions = {};

    // Iterate through each document in the snapshot
    for (QueryDocumentSnapshot doc in allPostsSnapshot.docs) {
      // Get the post data
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String description = data['description'];

      if (seenDescriptions.containsKey(description)) {
        // If the description is already seen, delete the current document
        await _firestore.collection('posts').doc(doc.id).delete();
        print('Deleted duplicate post with description: $description');
      } else {
        // Otherwise, add it to the seen descriptions map
        seenDescriptions[description] = doc.id;
      }
    }

    print('Cleanup completed. Duplicates have been removed.');
  } catch (e) {
    print('An error occurred while cleaning up duplicates: $e');
  }
}


  // Upload Post
  Future<String> uploadPost(String description, Uint8List file, String uid,
      String username, String profImage) async {
    String res = 'Some Error Occurred';
    try {

      DocumentSnapshot lastPostSnapshot = await _firestore
        .collection('user')
        .doc(uid)
        .get();

      if (lastPostSnapshot.exists && lastPostSnapshot.data() != null && (lastPostSnapshot.data() as Map<String, dynamic>).containsKey('lastPostTime')) {

        DateTime lastPostTime = (lastPostSnapshot.data() as Map<String, dynamic>)['lastPostTime'].toDate();
        DateTime currentTime = DateTime.now();

        // Calculate the difference in minutes
        int difference = currentTime.difference(lastPostTime).inSeconds;

        // Check if the difference is less than 5 minutes
        if (difference < 30) {
          return 'Failed!';
        } else {



          String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);
      String postId = const Uuid().v1();
      Post post = Post(
          description: description,
          uid: uid,
          username: username,
          postId: postId,
          datePublished: DateTime.now(),
          postUrl: photoUrl,
          profImage: profImage,
          likes: []);

      _firestore.collection('posts').doc(postId).set(post.toJson());

      await _firestore.collection('user').doc(uid).update({
      'lastPostTime': DateTime.now(),
      });

      res = 'success';


        }
    } else {


        String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);
      String postId = const Uuid().v1();
      Post post = Post(
          description: description,
          uid: uid,
          username: username,
          postId: postId,
          datePublished: DateTime.now(),
          postUrl: photoUrl,
          profImage: profImage,
          likes: []);

      _firestore.collection('posts').doc(postId).set(post.toJson());

        await _firestore.collection('user').doc(uid).update({
      'lastPostTime': DateTime.now(),
      });

      res = 'success';


    }


      
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<void> likePost(String uid, String postId, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      print(
        e.toString(),
      );
    }
  }

  Future<void> postComment(String postId, String text, String uid, String name, String profilePic) async {
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now()
        });
      } else {
        print('Text is empty');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap = await _firestore.collection('user').doc(uid).get();
      List following = (snap.data()! as Map)['following'];
      if (following.contains(followId)) {
        await _firestore.collection('user').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('user').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {

        await _firestore.collection('user').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        await _firestore.collection('user').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });

      }
    } catch(e) {
      print(e.toString());
    }
  }
}
