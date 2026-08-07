import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../const/constants.dart';

String normalizeWithdrawStatus(dynamic raw) {
  final value = (raw ?? 'pending').toString().trim().toLowerCase();
  switch (value) {
    case 'accepted':
    case 'approved':
    case 'completed':
    case 'success':
      return 'Accepted';
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return 'Cancelled';
    default:
      return 'Pending';
  }
}

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
        title: const Text('Withdrawal Requests'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Net / VAT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Request Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final requests = snapshot.data?.docs ?? [];
                if (requests.isEmpty) {
                  return const Center(child: Text('No requests found.'));
                }

                // Newest first when possible
                final sorted = [...requests];
                sorted.sort((a, b) {
                  final aTime = a.data() is Map
                      ? (a.data() as Map)['requestTime']
                      : null;
                  final bTime = b.data() is Map
                      ? (b.data() as Map)['requestTime']
                      : null;
                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }
                  return 0;
                });

                return ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final request = sorted[index];
                    final data = request.data() as Map<String, dynamic>? ?? {};
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    final net =
                        (data['netPayoutAmount'] as num?)?.toDouble();
                    final vat = (data['vatAmount'] as num?)?.toDouble();
                    final requestTime = data['requestTime'];
                    final status =
                        normalizeWithdrawStatus(data['withdrawStatus']);

                    String timeLabel = 'N/A';
                    if (requestTime is Timestamp) {
                      timeLabel = DateFormat('yyyy-MM-dd HH:mm')
                          .format(requestTime.toDate());
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 5),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${amount.toStringAsFixed(2)} AED',
                                  style: const TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  net != null
                                      ? 'Net ${net.toStringAsFixed(2)}\nVAT ${(vat ?? 0).toStringAsFixed(2)}'
                                      : '—',
                                  style: const TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  timeLabel,
                                  style: const TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: StatusDropdown(
                                  userId: userId,
                                  requestId: request.id,
                                  initialStatus: status,
                                  withdrawAmount: amount,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.grey, thickness: 2),
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
  final double withdrawAmount;

  const StatusDropdown({
    Key? key,
    required this.userId,
    required this.requestId,
    required this.initialStatus,
    required this.withdrawAmount,
  }) : super(key: key);

  @override
  _StatusDropdownState createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<StatusDropdown> {
  late String _selectedStatus;
  bool _updating = false;

  final List<String> _statuses = ['Pending', 'Accepted', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = normalizeWithdrawStatus(widget.initialStatus);
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_updating) return;
    setState(() {
      _updating = true;
      _selectedStatus = newStatus;
    });

    try {
      final withdrawalRequestRef = FirebaseFirestore.instance
          .collection('userWithdrawals')
          .doc(widget.userId)
          .collection('withdrawalsRequest')
          .doc(widget.requestId);

      final walletRef =
          FirebaseFirestore.instance.collection('wallet').doc(widget.userId);

      // Persist lowercase to match app writes, keep UI label capitalized.
      final storedStatus = newStatus.toLowerCase();

      if (newStatus == 'Cancelled') {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final walletSnap = await tx.get(walletRef);
          final current =
              (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0;
          tx.set(
            walletRef,
            {'balance': current + widget.withdrawAmount},
            SetOptions(merge: true),
          );
          tx.set(
            withdrawalRequestRef,
            {
              'withdrawStatus': storedStatus,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        });
      } else {
        await withdrawalRequestRef.set({
          'withdrawStatus': storedStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      debugPrint('Error updating withdraw status: $e');
      if (mounted) {
        setState(() {
          _selectedStatus = normalizeWithdrawStatus(widget.initialStatus);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStatus == 'Accepted') {
      return const Center(
        child: Text(
          'Accepted',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
    }
    if (_selectedStatus == 'Cancelled') {
      return const Center(
        child: Text(
          'Cancelled',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    }

    if (_updating) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        dropdownColor: Colors.white,
        iconSize: 20,
        iconEnabledColor: Colors.black,
        isExpanded: true,
        value: _selectedStatus,
        items: _statuses.map((String status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) async {
          if (newValue != null && newValue != _selectedStatus) {
            await _updateStatus(newValue);
          }
        },
        underline: const SizedBox.shrink(),
      ),
    );
  }
}
