import 'package:flutter/material.dart';
import 'package:flutter_test_chatapp/mixin/dialog_mixin.dart';
import 'package:flutter_test_chatapp/model/chatroom_model.dart';
import 'package:flutter_test_chatapp/screen/chat/message_list_screen.dart';
import 'package:flutter_test_chatapp/widget/front_container_widget.dart';

import '../../cache/preference_helper.dart';
import '../../routes.dart';
import '../../service/firestore_access.dart';

class ChatroomListScreen extends StatefulWidget {
  static const String ROUTE_NAME = '/chatroom_list_screen';

  const ChatroomListScreen({Key? key}) : super(key: key);

  @override
  State<ChatroomListScreen> createState() => _ChatroomListScreenState();
}

class _ChatroomListScreenState extends State<ChatroomListScreen>
    with DialogMixin {
  TextEditingController nicknameController = TextEditingController(text: '');


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _onPressedNewRoom,
      ),
      appBar: AppBar(
        centerTitle: true,
        leading: Container(),
        title: Text('IZ Talk'),
        actions: [
          MaterialButton(
            onPressed: _showNicknameDlg,
            child: Text(
              '닉네임 변경',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: StreamBuilder<List<ChatroomModel>>(
        stream: FirestoreAccess().streamChatrooms(), //중계하고 싶은 Stream을 넣는다.
        builder: (context, asyncSnapshot) {
          //return Container();
          if (!asyncSnapshot.hasData) {
            //데이터가 없을 경우 로딩위젯을 표시한다.
            return const Center(child: CircularProgressIndicator());
          } else if (asyncSnapshot.hasError) {
            return const Center(
              child: Text('오류가 발생했습니다.'),
            );
          } else {
            List<ChatroomModel> chatrooms =
                asyncSnapshot.data!; //비동기 데이터가 존재할 경우 리스트뷰 표시

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  children: _getChatroomItems(chatrooms),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  List<Widget> _getChatroomItems(List<ChatroomModel> chatrooms) {
    List<Widget> widgets = [];
    chatrooms.forEach((element) {
      widgets.add(FrontContainerWidget(
          onTap: () {

            Navigator.pushNamed(context, Routes.messageList,
                arguments: element);
          },
          child: Padding(
            padding: EdgeInsets.only(left: 15, top: 15, bottom: 15, right: 40),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [element.password!=''?Icon(Icons.lock,size: 16,):Container(), Text(element.name)],
            ),
          )));
    });
    return widgets;
  }

  void _showNicknameDlg() {
    showDialog(
        context: context,
        builder: (context) {
          Size screenSize = MediaQuery.of(context).size;
          return Dialog(
            child: Container(
              height: 200,
              width: 100,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '표시할 닉네임을 입력하세요.',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    TextField(
                      controller: nicknameController,
                      decoration: InputDecoration(hintText: 'ex)근육쟁이'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(),
                        ),
                        MaterialButton(
                          onPressed: _onPressedEditNickname,
                          child: Text('완료'),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  void _onPressedNewRoom() async {
    TextEditingController roomNameController = TextEditingController(text: '');
    TextEditingController passwordController = TextEditingController(text: '');
    bool isUsePassword = false;
    final result = await showCardDialog(context,
        titleChild: Center(
          child: Text('채팅방 생성'),
        ),
        height: 300,
        contentChild: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: StatefulBuilder(
            builder: (context,setDialogState){
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(),
                  TextField(
                    controller: roomNameController,
                    decoration: InputDecoration(hintText: '채팅방 이름'),
                  ),
                  Row(children: [
                    Text('암호'),
                    Checkbox(value: isUsePassword, onChanged: (value){setDialogState((){ isUsePassword = value??false;});}),
                    Expanded(
                      child: TextField(
                        enabled: isUsePassword,
                        controller: passwordController,
                      ),
                    )
                  ],),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [MaterialButton(onPressed: () {
                      if(roomNameController.text.trim()==''){
                        showAlertDialog(context, title: '경고', content: '채팅방 이름을 입력하세요.');
                        return;
                      }

                      if(isUsePassword&&passwordController.text.trim()==''){
                        showAlertDialog(context, title: '경고', content: '패스워드를 입력하세요.');
                        return;
                      }

                      Navigator.pop(context,true);},child: Text('완료'),)],
                  )
                ],
              );
            },
          ),
        ));
    if(result == true){
      ChatroomModel chatroomModel = ChatroomModel(
        name: roomNameController.text,
        password: isUsePassword?passwordController.text:'',
      );
      FirestoreAccess().addChatroom(chatroomModel: chatroomModel);
    }
  }


  void _onPressedEditNickname() {
    if (nicknameController.text.trim() == '') {
      showAlertDialog(context, title: '주의', content: '닉네임을 입력해주세요');
      return;
    }
    PrefernceHelper().setNickname(nicknameController.text);
    Navigator.pop(context);
  }
}