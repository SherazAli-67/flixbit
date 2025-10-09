import 'package:flixbit/src/features/seller/seller_registration_page.dart';
import 'package:flixbit/src/providers/profile_provider.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/widgets/loading_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerDashboardPage extends StatelessWidget{
  const SellerDashboardPage({super.key});


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    return provider.loading
        ? LoadingWidget()
        : provider.isRegisteredAsSeller
        ?  Center(child: Text("Seller Found"),): _buildRegisterAsSellerWidget(context);
  }

  _buildRegisterAsSellerWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 40,
          children: [
            Column(
              spacing: 15,
              children: [

                Text("404", style: AppTextStyles.headingTextStyle,),
                Text("Seller not found, Create Seller account first", style: AppTextStyles.smallTextStyle,),
              ],
            ),
            PrimaryBtn(btnText: "Register as Seller", icon: '', onTap: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (_)=> SellerRegistrationPage()));
          /*    showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return FractionallySizedBox(
                      heightFactor: 0.82,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: SellerRegistrationPage(),
                      ),
                    );
                  });*/
            })
          ],
        ),
      ),
    );
  }

}