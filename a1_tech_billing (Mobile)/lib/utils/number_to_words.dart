class NumberToWords {
  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  static String convert(int n) {
    if (n == 0) return 'Zero';

    String words = '';

    if (n >= 10000000) {
      words += '${convert(n ~/ 10000000)} Crore ';
      n %= 10000000;
    }

    if (n >= 100000) {
      words += '${convert(n ~/ 100000)} Lakh ';
      n %= 100000;
    }

    if (n >= 1000) {
      words += '${convert(n ~/ 1000)} Thousand ';
      n %= 1000;
    }

    if (n >= 100) {
      words += '${convert(n ~/ 100)} Hundred ';
      n %= 100;
    }

    if (n > 0) {
      if (words.isNotEmpty) {
        words += 'and ';
      }

      if (n < 20) {
        words += _units[n];
      } else {
        words += _tens[n ~/ 10];
        if ((n % 10) > 0) {
          words += ' ${_units[n % 10]}';
        }
      }
    }

    return words.trim();
  }

  static String convertAmount(double amount) {
    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    String result = 'Rupees ${convert(rupees)} Only';
    
    if (paise > 0) {
      result = 'Rupees ${convert(rupees)} and ${convert(paise)} Paise Only';
    }
    
    return result;
  }
}
