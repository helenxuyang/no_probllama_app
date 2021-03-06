import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Event.dart';
import 'CreateEvent.dart';
import 'Login.dart';
import 'Utils.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String userID = Provider.of<CurrentUserInfo>(context).id;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: SizedBox(
              child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Text('Discover Events',
                            style: Theme.of(context).textTheme.headline1),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.filter_list),
                          onPressed: () {
                            //TODO: add filter options
                          },
                        )
                      ]),
                    ),
                    EventGroup(
                        'Happening Now',
                        FirebaseFirestore.instance
                            .collection('events')
                            .where('startTime', isLessThan: Timestamp.now())
                            .orderBy('startTime')
                            .snapshots()),
                    SizedBox(height: 24),
                    StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userID)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container();
                          }
                          List<String> interestedTags = List<String>.from(snapshot.data.get('interestedTags'));
                          List<String> otherTags = Utils.allTags.where((tag) => !interestedTags.contains(tag)).toList();
                          List<Widget> interestedGroups = interestedTags.map((tag) => EventGroup(
                              '#$tag',
                              FirebaseFirestore.instance
                                  .collection('events')
                                  .where('tags', arrayContains: tag)
                                  .snapshots()))
                              .toList();
                          List<Widget> otherGroups = otherTags.map((tag) => EventGroup(
                              '#$tag',
                              FirebaseFirestore.instance
                                  .collection('events')
                                  .where('tags', arrayContains: tag)
                                  .snapshots()))
                              .toList();
                          return ListView(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                Text('Your Tags', style: Theme.of(context).textTheme.headline2),
                                interestedGroups.isEmpty ? EventUtils.noEventsMessage :
                                ListView(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: interestedGroups
                                ),
                                SizedBox(height: 16),
                                Text('Other Events', style: Theme.of(context).textTheme.headline2),
                                otherGroups.isEmpty ? EventUtils.noEventsMessage :
                                ListView(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: otherGroups
                                ),
                              ]
                          );
                        })
                  ]),
            ),
          ),
        ),
        Positioned(
            bottom: 16,
            right: 8,
            child: FloatingActionButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return CreateEventPage();
                      });
                },
                child: Icon(Icons.add)
            )
        ),
      ],
    );
  }
}

class EventGroup extends StatelessWidget {
  EventGroup(this.title, this.stream);

  final String title;
  final Stream stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        List<DocumentSnapshot> docs =
        List<DocumentSnapshot>.from(snapshot.data.documents).where((doc) {
          return doc.get('endTime').seconds > Timestamp.now().seconds;
        }).toList();
        docs = docs.sublist(0, min(3, docs.length));
        if (docs.isEmpty) {
          return Container();
        }
        Widget eventGroupPage =
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlatButton(
                      padding: EdgeInsets.only(left: 0),
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      child: Align(
                          alignment: Alignment.centerLeft, child: Text('Back')),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(title, style: Theme.of(context).textTheme.headline1),
                    SizedBox(height: 16),
                    Expanded(
                      child: Scrollbar(
                        child: ListView(
                            children: List<EventCard>.from(docs.map((doc) {
                              return EventCard(Event.fromDoc(doc));
                            }))),
                      ),
                    )
                  ]),
            )
          )
        );
        return Column(
            children: [
              Row(children: [
                Text(title, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Theme.of(context).accentColor)),
                Spacer(),
                FlatButton(
                    child: Text('view all',
                        style: TextStyle(
                            fontSize: 14, color: Theme.of(context).accentColor)),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => eventGroupPage));
                    })
              ]),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: List<EventCard>.from(docs.map((doc) {
                  return EventCard(Event.fromDoc(doc));
                }))),
              )
            ]);
      },
    );
  }
}