import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../const/constants.dart';

class WithdrawalRequest extends StatelessWidget {
  final String userId;

  const WithdrawalRequest({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Requests Details'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                // SizedBox(width: 65),
                Expanded(
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text('Acc Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Acc No',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('CVC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Request Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Withdraw Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('userWithdrawals')
                  .doc(userId)
                  .collection('withdrawalsRequest')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: hama'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var requests = snapshot.data!.docs;

                if (requests.isEmpty) {
                  return Center(
                    child: Text('No Requests found.'),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var request = requests[index];
                    var amount = request['amount'];
                    var accountName = request['accountName'];
                    var accountNumber = request['accountNumber'];
                    var cvc = request['cvc'];
                    var requestTime = request['requestTime'];
                    var status = request['withdrawStatus'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 5),
                      child: Column(
                        children: [
                          Row(
                            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // SizedBox(width: 65),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  amount.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  accountName,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  accountNumber,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  cvc,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  DateFormat('yyyy-MM-dd HH:mm').format(
                                    requestTime.toDate(),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: StatusDropdown(
                                  userId: userId,
                                  requestId: request.id,
                                  initialStatus: status,
                                  withdrawamount: amount,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.grey,
                            thickness: 2,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StatusDropdown extends StatefulWidget {
  final String userId;
  final String requestId;
  final String initialStatus;
  final double withdrawamount;

  const StatusDropdown({
    Key? key,
    required this.userId,
    required this.requestId,
    required this.initialStatus,
    required this.withdrawamount,
  }) : super(key: key);

  @override
  _StatusDropdownState createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<StatusDropdown> {
  late String _selectedStatus;

  final List<String> _statuses = ['Accepted', 'Cancelled', 'Pending'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statuses.contains(widget.initialStatus)
        ? widget.initialStatus
        : 'Pending'; // Default to 'Pending' if initial status is invalid
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      setState(() {
        _selectedStatus = newStatus;
      });
      var withdrawalRequestRef = FirebaseFirestore.instance
          .collection('userWithdrawals')
          .doc(widget.userId)
          .collection('withdrawalsRequest')
          .doc(widget.requestId);

      var walletRef =
          FirebaseFirestore.instance.collection('wallet').doc(widget.userId);

      if (_selectedStatus == 'Cancelled') {
        // Get the current withdrawal amount

        var withdrawAmountusd = widget.withdrawamount;

        // Get the current wallet balance
        var wallet = await walletRef.get();
        var currentBalanceusd = wallet['balance'];

        // Update the wallet balance
        var newBalance = currentBalanceusd + withdrawAmountusd;

        await walletRef.update({
          'balance': newBalance,
        });
        await withdrawalRequestRef.update({'withdrawStatus': newStatus});
      } else if (_selectedStatus == 'Accepted') {
        await withdrawalRequestRef.update({'withdrawStatus': newStatus});
      }
      print('object');
    } catch (e) {
      print('Error$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStatus == 'Accepted') {
      return Center(
        child: Text(
          'Accepted',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
    }
    if (_selectedStatus == 'Cancelled') {
      return Center(
        child: Text(
          'Cancelled',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: DropdownButton<String>(
        dropdownColor: Colors.white,
        iconSize: 20,
        // iconDisabledColor: Colors.red,
        iconEnabledColor: Colors.black,

        // style: TextStyle(color: Colors.red),
        isExpanded: true,
        value: _selectedStatus,
        items: _statuses.map((String status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Text(
              status,
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 15),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) async {
          if (newValue != null) {
            await _updateStatus(newValue);
          }
        },
        underline: SizedBox.shrink(),
      ),
    );
  }
}
