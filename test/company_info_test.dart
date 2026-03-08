import 'package:deadline_note/src/services/company_info_service.dart';

void main() async {
  print('Fetching company info for Samsung...');
  final info = await CompanyInfoService.fetchCompanyInfo('Samsung');
  
  print('--- Summary ---');
  print(info.summary);
  
  print('\n--- News Summary ---');
  print(info.newsSummary);
  
  print('\n--- Source URLs ---');
  for (var url in info.sourceUrls) {
    print(url);
  }
}
