/// Anketi dolduran müşteri. Verildiğinde cevap bu müşteriye ve işleme bağlı kaydedilir;
/// verilmezse cevap anonimdir. Alanlar Partner API'deki karşılıklarıyla gönderilir.
class OnayliyorumUser {
  const OnayliyorumUser({
    required this.externalId,
    required this.name,
    this.transaction,
    this.phoneNumber,
    this.email,
  });

  /// Müşterinin sizin sisteminizdeki kimliği (`external_id`).
  final String externalId;
  final String name;

  /// Ülke koduyla, örn. `905xxxxxxxxx` (`phone_number`).
  final String? phoneNumber;
  final String? email;

  /// Anketin ilgili olduğu alışveriş / işlem (isteğe bağlı).
  ///
  /// Verilirse müşteri bu işlem için anketi yalnızca bir kez cevaplayabilir. Verilmezse
  /// (satış dışı gösterimler) cevap yine müşteriye bağlanır ve anket her açılışta cevaplanabilir.
  final OnayliyorumTransaction? transaction;

  Map<String, dynamic> toJson() => {
        'external_id': externalId,
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        if (transaction != null) 'transaction': transaction!.toJson(),
      };
}

/// Anketin ilgili olduğu işlem. [invoiceCrmNo] ya da [invoiceNo] ile [transactionDate] birlikte zorunludur.
/// Aynı müşteri aynı işlem için anketi yalnızca bir kez cevaplayabilir.
class OnayliyorumTransaction {
  const OnayliyorumTransaction({
    this.invoiceNo,
    this.invoiceCrmNo,
    this.transactionDate,
    this.channel,
    this.branchName,
    this.orderLocation,
    this.subchannel,
    this.orderChannel,
    this.orderLocationId,
    this.billingType,
    this.homeDelivery,
    this.branchFullName,
    this.transactionChannel,
  }) : assert(
          invoiceCrmNo != null || (invoiceNo != null && transactionDate != null),
          'invoiceCrmNo ya da invoiceNo ile transactionDate verilmelidir.',
        );

  /// `fatura_no`
  final String? invoiceNo;

  /// `fatura_crm_no`
  final String? invoiceCrmNo;

  /// `transaction_date`
  final DateTime? transactionDate;

  /// `channel`
  final String? channel;

  /// `branch_name`
  final String? branchName;

  /// `orderlocation`
  final String? orderLocation;

  /// `subchannel`
  final String? subchannel;

  /// `orderchannel`
  final String? orderChannel;

  /// `orderlocationid`
  final String? orderLocationId;

  /// `faturalama_turu`
  final String? billingType;

  /// `eve_teslim`
  final String? homeDelivery;

  /// `branch_fullName`
  final String? branchFullName;

  /// `transactionchannel`
  final int? transactionChannel;

  Map<String, dynamic> toJson() => {
        'fatura_no': invoiceNo,
        'fatura_crm_no': invoiceCrmNo,
        'transaction_date': transactionDate == null ? null : _formatDate(transactionDate!),
        'channel': channel,
        'branch_name': branchName,
        'orderlocation': orderLocation,
        'subchannel': subchannel,
        'orderchannel': orderChannel,
        'orderlocationid': orderLocationId,
        'faturalama_turu': billingType,
        'eve_teslim': homeDelivery,
        'branch_fullName': branchFullName,
        'transactionchannel': transactionChannel,
      };
}

// Partner API ile aynı biçim: MM/dd/yyyy HH:mm:ss
String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.month)}/${two(date.day)}/${date.year} ${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
}

/// Kullanıcı bilgisiyle açılan anket oturumu.
class OnayliyorumSession {
  const OnayliyorumSession({required this.referenceNumber, required this.alreadyAnswered});

  /// Cevabı müşteriye bağlayan referans; anket adresine eklenir.
  final String referenceNumber;

  /// Müşteri bu işlem için anketi daha önce cevaplamış.
  final bool alreadyAnswered;
}
