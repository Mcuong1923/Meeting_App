import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting_minutes_model.dart';
import 'package:provider/provider.dart';
import '../providers/meeting_minutes_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';

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
                          
                          // Floating Format Button
                          if (canEdit)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Material(
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
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Bottom padding for scroll
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
