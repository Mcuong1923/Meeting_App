import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting_minutes_model.dart';
import 'package:provider/provider.dart';
import '../providers/meeting_minutes_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/file_provider_simple.dart';
import '../models/user_role.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gemini_service.dart';

class MeetingMinutesEditorScreen extends StatefulWidget {
  final String meetingId;
  final MeetingMinutesModel? existingMinutes;

  const MeetingMinutesEditorScreen({
    Key? key,
    required this.meetingId,
    this.existingMinutes,
  }) : super(key: key);

  @override
  State<MeetingMinutesEditorScreen> createState() => _MeetingMinutesEditorScreenState();
}

class _MeetingMinutesEditorScreenState extends State<MeetingMinutesEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  
  bool _isDirty = false;
  bool _isSaving = false;
  String? _originalContent;
  String? _originalTitle;

  // --- Attachments ---
  List<PlatformFile> _pendingAttachments = [];
  List<Map<String, dynamic>> _uploadedAttachments = [];
  bool _isAttaching = false;

  // --- AI ---
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    final rawContent = widget.existingMinutes?.content ?? '';
    final plainContent = _stripHtml(rawContent);
    final initialTitle = widget.existingMinutes?.title ?? '';
    
    _originalContent = plainContent;
    _originalTitle = initialTitle;
    
    _contentController = TextEditingController(text: plainContent);
    _titleController = TextEditingController(text: initialTitle);
    
    _contentController.addListener(_onDataChanged);
    _titleController.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onDataChanged);
    _titleController.removeListener(_onDataChanged);
    _contentController.dispose();
    _titleController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  String _stripHtml(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'</p>'), '\n\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    return text.trim();
  }

  void _onDataChanged() {
    final isContentDirty = _contentController.text != _originalContent;
    final isTitleDirty = _titleController.text != _originalTitle;
    final isDirty = isContentDirty || isTitleDirty;
    
    if (isDirty != _isDirty) {
      setState(() => _isDirty = isDirty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.existingMinutes?.canEdit ?? true;
    final versionParam = widget.existingMinutes?.versionNumber;
    final statusText = widget.existingMinutes?.statusText ?? 'Bản nháp';
    final updatedAt = widget.existingMinutes?.updatedAt ?? DateTime.now();
    final updatedByName = widget.existingMinutes?.updatedByName ?? 'Tôi';
    
    // Calculate total chars
    final totalChars = _titleController.text.length + _contentController.text.length;

    return WillPopScope(
      onWillPop: () async {
        if (_isDirty) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1A1A1A)),
            onPressed: _handleBack,
          ),
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                'Chỉnh sửa biên bản',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (versionParam != null)
                Text(
                  'Phiên bản #$versionParam • $statusText ${_isDirty ? "• Chưa lưu" : ""}',
                  style: TextStyle(
                    color: _isDirty ? Colors.orange : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade50,
                ),
                child: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF1A1A1A)),
              ),
              offset: const Offset(0, 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              surfaceTintColor: Colors.white,
              color: Colors.white,
              elevation: 4,
              tooltip: 'Tùy chọn',
              onSelected: (value) {
                 if (value == 'submit') _showSubmitDialog();
                 if (value == 'preview') _showPreview();
                 if (value == 'clear') _contentController.clear();
              },
              itemBuilder: (context) => [
                if (canEdit)
                  PopupMenuItem(
                    value: 'submit',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(width: 12),
                        const Text('Gửi duyệt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(width: 12),
                      const Text('Xem trước', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    ],
                  ),
                ),
                if (canEdit) ...[
                  const PopupMenuDivider(height: 16),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFC62828)),
                        ),
                        const SizedBox(width: 12),
                        const Text('Xóa nội dung', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Info Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildStatusChip(widget.existingMinutes?.status ?? MinutesStatus.draft),
                              const Spacer(),
                              if (_isDirty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Chưa lưu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  '$totalChars ký tự',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(
                                'Cập nhật: $updatedByName • ${DateFormat('HH:mm dd/MM').format(updatedAt)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Section 1.5: Title Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _titleController,
                        enabled: canEdit,
                        maxLength: 120, // Spec: 80-120
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'VD: Biên bản họp ngày 28/01',
                          labelText: 'Tiêu đề',
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.normal,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: "", // Hide default counter
                        ),
                      ),
                    ),

                    // Section 2: Editor Card (Content)
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 220, // Min height spec
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // TextField
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 56), // Bottom padding for FAB
                            child: TextField(
                              controller: _contentController,
                              focusNode: _contentFocusNode,
                              maxLines: null,
                              minLines: 8,
                              enabled: canEdit,
                              scrollPhysics: const NeverScrollableScrollPhysics(),
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF1A1A1A),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Nội dung',
                                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                alignLabelWithHint: true,
                                hintText: 'Nhập nội dung biên bản...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                            ),
                          ),
                          
                          // Floating buttons: AI ✨ + Format Aa
                          if (canEdit)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // AI Tóm tắt
                                  Tooltip(
                                    message: 'AI Tóm tắt biên bản',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isSummarizing ? null : _aiSummarize,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF7F56D9), Color(0xFF9E6DFF)],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF7F56D9).withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: _isSummarizing
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Text('✨', style: TextStyle(fontSize: 18)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Format Aa
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showFormattingSheet,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Aa',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Color(0xFF7F56D9),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Section 3: Tệp đính kèm
                    _buildAttachmentsCard(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Sticky Footer
            if (canEdit)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _handleBack,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveDraft,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F56D9), 
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Lưu nháp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// AI Tóm tắt biên bản dùng Gemini
  Future<void> _aiSummarize() async {
    final content = _contentController.text.trim();
    final title = _titleController.text.trim();

    if (content.isEmpty && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hãy nhập nội dung biên bản trước khi dùng AI!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        ),
      );
      return;
    }

    setState(() => _isSummarizing = true);
    try {
      final summary = await GeminiService.summarizeMinutes(
        title: title.isEmpty ? 'Biên bản cuộc họp' : title,
        content: content.isEmpty ? title : content,
      );

      if (!mounted) return;
      _showAiResultSheet(summary);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('$e')),
          ]),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  void _showAiResultSheet(String summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.82,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: const Color(0xFFF8F9FB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7F56D9), Color(0xFF9E6DFF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AI Tóm tắt Biên bản',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7F56D9),
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Intro Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F0FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.summarize_rounded, color: Color(0xFF7F56D9), size: 16),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Dưới đây là tóm tắt biên bản cuộc họp của bạn do AI tạo ra từ Gemini:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI GENERATED SUMMARY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF7F56D9),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tóm tắt Biên bản Cuộc họp',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                  height: 1.3,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildSummaryChip(Icons.auto_awesome_rounded, 'Gemini AI'),
                                  const SizedBox(width: 8),
                                  _buildSummaryChip(Icons.verified_rounded, 'Đã xác minh'),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 20),

                              // Summary content rendered as sections
                              ..._parseSummarySections(summary).map((section) =>
                                _buildSummarySection(section),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Note card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lưu ý khi sử dụng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Kết quả tóm tắt này được AI tạo ra dựa trên nội dung biên bản bạn đã nhập. Hãy đọc kỹ và chỉnh sửa nếu cần trước khi lưu chính thức.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildSummaryTag('GEMINI AI'),
                                  const SizedBox(width: 8),
                                  _buildSummaryTag('TÓM TẮT TỰ ĐỘNG'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Primary button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final current = _contentController.text;
                            final separator = current.isEmpty ? '' : '\n\n---\n**📌 Tóm tắt AI:**\n';
                            _contentController.text = '$current$separator$summary';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF7F56D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Chèn vào biên bản',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Secondary button
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFFE2E8F0),
                            foregroundColor: const Color(0xFF475569),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7F56D9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7F56D9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7F56D9),
        ),
      ),
    );
  }

  List<Map<String, String>> _parseSummarySections(String text) {
    final sections = <Map<String, String>>[];
    final lines = text.split('\n');
    String currentHeader = '';
    final currentBody = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      // Detect bold headers like **Tóm tắt nội dung chính:** or ## Title
      final headerMatch = RegExp(r'^\*\*(.+?)\*\*:?\s*$|^#{1,3}\s+(.+)$').firstMatch(trimmed);
      if (headerMatch != null) {
        if (currentHeader.isNotEmpty || currentBody.isNotEmpty) {
          sections.add({'header': currentHeader, 'body': currentBody.toString().trim()});
          currentBody.clear();
        }
        currentHeader = (headerMatch.group(1) ?? headerMatch.group(2) ?? '').replaceAll('**', '').replaceAll(':', '').trim();
      } else if (trimmed.isNotEmpty) {
        // Strip inline markdown bold
        final cleaned = trimmed.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1').replaceAll('*', '');
        currentBody.writeln(cleaned);
      }
    }
    if (currentHeader.isNotEmpty || currentBody.isNotEmpty) {
      sections.add({'header': currentHeader, 'body': currentBody.toString().trim()});
    }
    if (sections.isEmpty) {
      sections.add({'header': 'Nội dung tóm tắt', 'body': text.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1').replaceAll('*', '').trim()});
    }
    return sections;
  }

  Widget _buildSummarySection(Map<String, String> section) {
    final header = section['header'] ?? '';
    final body = section['body'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F56D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    header,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Card tệp đính kèm
  Widget _buildAttachmentsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.attach_file_rounded,
                  size: 18, color: Color(0xFF7F56D9)),
              const SizedBox(width: 8),
              const Text(
                'Tệp đính kèm',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isAttaching ? null : _pickAttachment,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_rounded,
                          size: 16, color: Color(0xFF7F56D9)),
                      SizedBox(width: 4),
                      Text('Chọn tệp',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7F56D9))),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Pending files preview
          if (_pendingAttachments.isNotEmpty) ...([
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã chọn ${_pendingAttachments.length} tệp:',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F56D9)),
                  ),
                  const SizedBox(height: 6),
                  ..._pendingAttachments.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_rounded,
                                size: 14, color: Color(0xFF7F56D9)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(f.name,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              f.size < 1024 * 1024
                                  ? '${(f.size / 1024).toStringAsFixed(0)} KB'
                                  : '${(f.size / 1024 / 1024).toStringAsFixed(1)} MB',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isAttaching
                        ? null
                        : () => setState(() => _pendingAttachments = []),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Hủy',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isAttaching ? null : _uploadAttachments,
                    icon: _isAttaching
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload_rounded, size: 16),
                    label: Text(
                      _isAttaching ? 'Đang tải...' : 'Tải lên',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F56D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ]),

          // Already uploaded
          if (_uploadedAttachments.isNotEmpty) ...([
            const SizedBox(height: 12),
            ..._uploadedAttachments.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final url = f['downloadUrl'] as String?;
                      if (url != null) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F0FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.insert_drive_file_rounded,
                                size: 16, color: Color(0xFF7F56D9)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f['originalName'] as String? ?? f['name'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.download_rounded,
                              size: 16, color: Color(0xFF7F56D9)),
                        ],
                      ),
                    ),
                  ),
                )),
          ]),

          if (_pendingAttachments.isEmpty && _uploadedAttachments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Chưa có tệp nào. Nhấn "Chọn tệp" để đính kèm.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          allowMultiple: true, type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pendingAttachments = result.files);
      }
    } catch (e) {
      debugPrint('Pick error: $e');
    }
  }

  Future<void> _uploadAttachments() async {
    if (_pendingAttachments.isEmpty) return;
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() => _isAttaching = true);
    try {
      final provider = context.read<SimpleFileProvider>();
      final results = await Future.wait(
        _pendingAttachments.map((f) => provider.uploadFiles(
              [f], user.id, user.displayName,
              meetingId: widget.meetingId)),
      );
      // Collect uploaded file metadata from provider.files
      final uploaded = provider.files
          .where((f) =>
              results.expand((ids) => ids).contains(f['id']))
          .toList();
      setState(() {
        _uploadedAttachments = [...uploaded, ..._uploadedAttachments];
        _pendingAttachments = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Đã đính kèm ${uploaded.length} tệp thành công!'),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin:
                const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAttaching = false);
    }
  }

  Widget _buildStatusChip(MinutesStatus status) {
    Color bg;
    Color text;
    String label;
    
    switch (status) {
      case MinutesStatus.draft:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
        label = 'Bản nháp';
        break;
      case MinutesStatus.pending_approval:
        bg = Colors.orange.withOpacity(0.1);
        text = Colors.orange;
        label = 'Chờ duyệt';
        break;

      case MinutesStatus.approved:
        bg = Colors.green.withOpacity(0.1);
        text = Colors.green.shade700;
        label = 'Đã duyệt';
        break;
      case MinutesStatus.rejected:
        bg = Colors.red.withOpacity(0.1);
        text = Colors.red.shade700;
        label = 'Từ chối';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFormattingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Định dạng văn bản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFormatOption(Icons.format_bold_rounded, 'Đậm', () => _insertMarkdown('**', '**')),
                    _buildFormatOption(Icons.format_italic_rounded, 'Nghiêng', () => _insertMarkdown('*', '*')),
                    _buildFormatOption(Icons.format_list_bulleted_rounded, 'Danh sách', () => _insertPrefix('- ')),
                    _buildFormatOption(Icons.format_list_numbered_rounded, 'Số thứ tự', () => _insertPrefix('1. ')),
                    _buildFormatOption(Icons.format_quote_rounded, 'Trích dẫn', () => _insertPrefix('> ')),
                    _buildFormatOption(Icons.link_rounded, 'Link', () => _insertMarkdown('[', '](url)')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    // Determine which controller to formatting? User said "Nút định dạng chữ đặt trong editor ... bottom-right của khung Nội dung".
    // So usually this applies to content controller.
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start < 0) {
      // If not focused or invalid selection, maybe just append? Or do nothing?
      // Better to prioritize explicit focus or default to content.
      // We'll check if content focus node has focus.
      if (!_contentFocusNode.hasFocus) {
         // Optionally request focus?
         _contentFocusNode.requestFocus();
         return; // Wait for next tick? Or just proceed if we assume end.
      }
      return; 
    }
    final newText = text.replaceRange(selection.start, selection.end, '$prefix${text.substring(selection.start, selection.end)}$suffix');
    _contentController.value = TextEditingValue(text: newText, selection: TextSelection(baseOffset: selection.start + prefix.length, extentOffset: selection.start + prefix.length + (selection.end - selection.start)));
  }

  void _insertPrefix(String prefix) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start < 0 || !_contentFocusNode.hasFocus) {
       if (!_contentFocusNode.hasFocus) _contentFocusNode.requestFocus();
       return;
    }
    final beforeCursor = text.substring(0, selection.start);
    final lastNewLine = beforeCursor.lastIndexOf('\n');
    final lineStart = lastNewLine == -1 ? 0 : lastNewLine + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _contentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: selection.start + prefix.length));
  }



  void _handleBack() async {
    if (_isDirty) {
      if (await _showUnsavedChangesDialog() == true) Navigator.pop(context);
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool?> _showUnsavedChangesDialog() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chưa lưu thay đổi'),
      content: const Text('Thoát sẽ làm mất các thay đổi này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ở lại')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Thoát')),
      ],
    ),
  );

  void _saveDraft() async {
    // Allows empty title for draft? "Nếu rỗng vẫn cho lưu nháp" -> YES.
    // Content can be empty? "content không rỗng (optional)". user says "Khi bấm Lưu nháp: Lưu cả title + content".
    if (_contentController.text.trim().isEmpty && _titleController.text.trim().isEmpty) return; // Nothing to save
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập lại'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    
    final provider = context.read<MeetingMinutesProvider>();
    final docId = await provider.upsertDraft(
      minutesId: widget.existingMinutes?.id,
      meetingId: widget.meetingId,
      title: _titleController.text.trim(),
      content: _contentController.text,
      userId: user.id,
      userName: user.displayName,
    );
    
    setState(() { 
      _isSaving = false; 
    });

    if (docId != null) {
      setState(() {
        _isDirty = false;
        _originalContent = _contentController.text;
        _originalTitle = _titleController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu nháp thành công ✓'), backgroundColor: Color(0xFF4CAF50)));
      
      // If created new (widget.existingMinutes was null), we typically want to replace the screen or update state
      // But for now, user stays on screen. We should probably pop or reload to get proper 'existingMinutes' context.
      // However, upsertDraft logic handles ID. If we want to continue editing, we need the new ID.
      // Ideally, pass new ID to this screen or just Pop with result.
      // Requirement: "After success: Show Snackbar... Navigate back OR stay".
      // Let's stay but we can't update 'widget.existingMinutes' easily. 
      // Simplest flow: Pop back so Detail screen refreshes and user sees it in list.
      // OR: Do nothing, just stay. Next save might create DUPLICATE if we don't have ID.
      // CRITICAL: We need to know the ID if we created new, to prevent duplicates on next save.
      // We'll navigate back for simplicity and correctness of lists.
      Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu nháp: ${provider.error}'), backgroundColor: Colors.red));
    }
  }

  void _showSubmitDialog() {
    // Validate title
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề biên bản'), backgroundColor: Colors.red));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi duyệt'),
        content: const Text('Gửi biên bản này để Admin duyệt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async { 
              Navigator.pop(context); // Close dialog
              
              final authProvider = context.read<AuthProvider>();
              final user = authProvider.userModel;
              if (user == null) return;

              // Ensure saved first?
              // Logic: Update content then submit status. 
              // Better: Trigger Save first if dirty? Or just submit current content as draft update then submit.
              // Our Submit API only takes ID. So we MUST save content first if dirty, or assume content is saved.
              // Let's save content first implicitly.
              
              if (_isDirty || widget.existingMinutes == null) {
                 // Must save first
                 final provider = context.read<MeetingMinutesProvider>();
                 final docId = await provider.upsertDraft(
                    minutesId: widget.existingMinutes?.id,
                    meetingId: widget.meetingId,
                    title: _titleController.text.trim(),
                    content: _contentController.text,
                    userId: user.id,
                    userName: user.displayName,
                 );
                 if (docId == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi lưu trước khi gửi'), backgroundColor: Colors.red));
                    return;
                 }
                 // Continue with this ID
                 _submit(docId, user);
              } else {
                 _submit(widget.existingMinutes!.id, user); // Safe ! since !dirty means loaded existing
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Gửi duyệt'),
          ),
        ],
      ),
    );
  }

  void _submit(String minutesId, dynamic user) async {
    setState(() => _isSaving = true);
    final provider = context.read<MeetingMinutesProvider>();
    final isAdmin = user.role == UserRole.admin;
    
    final success = await provider.submitForApproval(
      minutesId: minutesId, 
      isAdmin: isAdmin,
      userId: user.id,
      userName: user.displayName,
    );
    
    setState(() => _isSaving = false);
    
    if (success) {
      if (mounted) {
        String msg = isAdmin ? 'Đã duyệt biên bản thành công' : 'Đã gửi duyệt thành công';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50)));
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gửi duyệt: ${provider.error}'), backgroundColor: Colors.red));
    }
  }

  void _showPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_titleController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(_contentController.text, style: const TextStyle(fontSize: 16, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
