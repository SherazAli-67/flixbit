import 'package:flutter/material.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class UploadVideoAdPage extends StatelessWidget {
  const UploadVideoAdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload New Video Section
            _buildUploadNewVideoSection(),
            const SizedBox(height: 40),
            
            // Organize Videos Section
            _buildOrganizeVideosSection(),
            const SizedBox(height: 40),
            
            // Video Performance Section
            _buildVideoPerformanceSection(),
            const SizedBox(height: 40),
            
            // Reward Association Section
            _buildRewardAssociationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadNewVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upload New Video",
          style: AppTextStyles.headingTextStyle3,
        ),
        const SizedBox(height: 20),
        
        // Video Title
        _buildTextField("Video Title", "Enter video title"),
        const SizedBox(height: 16),
        
        // Video Description
        _buildTextField("Video Description", "Enter video description", maxLines: 4),
        const SizedBox(height: 16),
        
        // Video Link
        _buildTextField("Video Link (External)", "Paste external video link"),
        const SizedBox(height: 20),
        
        // File Upload Area
        _buildUploadArea(),
      ],
    );
  }

  Widget _buildOrganizeVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Organize Videos",
          style: AppTextStyles.headingTextStyle3,
        ),
        const SizedBox(height: 20),
        
        // Filters
        Row(
          children: [
            Expanded(
              child: _buildDropdown("Category", "All"),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown("Sort By", "Most Recent"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Video List
        _buildVideoList(),
      ],
    );
  }

  Widget _buildVideoPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Video Performance",
          style: AppTextStyles.headingTextStyle3,
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(child: _buildMetricCard("Total Views", "1,234")),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("Avg. Watch Time", "2:30")),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("Rewards Given", "500")),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardAssociationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Reward Association",
          style: AppTextStyles.headingTextStyle3,
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: _buildDropdown("Video", "Select video"),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown("Reward", "Select reward"),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // Associate Reward Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Associate Reward",
              style: AppTextStyles.buttonTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.smallBoldTextStyle,
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          style: AppTextStyles.bodyTextStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hintTextStyle,
            filled: true,
            fillColor: AppColors.cardBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.uploadAreaColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor,
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: AppColors.uploadTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            "Click to upload or drag and drop",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.uploadTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "MP4, MOV, AVI up to 500MB",
            style: AppTextStyles.lightGrayRegular14,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.smallBoldTextStyle,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: AppTextStyles.bodyTextStyle,
              dropdownColor: AppColors.cardBgColor,
              items: [value].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoList() {
    return Column(
      children: [
        _buildVideoItem(
          "Product Demo Video",
          "Uploaded 2 days ago",
          Icons.play_circle_filled,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildVideoItem(
          "Brand Story Video",
          "Uploaded 1 week ago",
          Icons.movie,
          Colors.brown,
        ),
      ],
    );
  }

  Widget _buildVideoItem(String title, String uploadTime, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  uploadTime,
                  style: AppTextStyles.lightGrayRegular12,
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_vert,
            color: AppColors.lightGreyColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.lightGrayRegular14,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.whiteBold20,
          ),
        ],
      ),
    );
  }
}