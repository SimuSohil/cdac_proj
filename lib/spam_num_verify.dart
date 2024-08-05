import 'dart:core';
import 'dart:developer';

String normalizePhoneNumber(String phoneNumber) {
  // Remove any non-digit characters (e.g., '+', '-', ' ')
  phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
  // Remove country code if it starts with '91' or any other specific country code
  if (phoneNumber.startsWith('91')) {
    phoneNumber = phoneNumber.substring(2);
  }
  // Add more conditions for other country codes if needed
  return phoneNumber;
}

// Sample List for Global Blacklist
List<String> scamNumbers = [
  "+919360468002",
  "+442034567890",
  "+919345673812",
]; 

// Sample List for Global Whitelist
List<String> whiteListNumbers = [
  "+919876543210",
  "+441234567890",
  "+919012345678",
]; 

Future<bool> reportSpamNumber(String phoneNumber) async {
  String normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);
  log('Normalized phone number: $normalizedPhoneNumber');

  bool isScam = scamNumbers.any((number) {
    String normalizedScamNumber = normalizePhoneNumber(number);
    log('Comparing with scam number: $normalizedScamNumber');
    return normalizedScamNumber == normalizedPhoneNumber;
  });

  bool isWhiteListed = whiteListNumbers.any((number) {
    String normalizedWhiteListNumber = normalizePhoneNumber(number);
    log('Comparing with whitelist number: $normalizedWhiteListNumber');
    return normalizedWhiteListNumber == normalizedPhoneNumber;
  });

  if (isWhiteListed) {
    log('This number ($phoneNumber) is in your whitelist.');
  } else if (isScam) {
    log('This number ($phoneNumber) is reported as a scam!');
  } else {
    log('This number ($phoneNumber) is not currently on the blacklist or whitelist.');
  }

  return isScam;
}

// Example usage
void main() {
  String incomingNumber = '+919012345678';
  reportSpamNumber(incomingNumber);
}
