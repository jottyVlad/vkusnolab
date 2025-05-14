import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Для скролла
import 'home_page.dart';
import 'create_recipe_page.dart';
import 'profile_page.dart';
import 'product_list.dart';
import 'services/chat_service.dart'; // Импорт сервиса и модели
import 'auth_service.dart'; // Исправлен путь и импорт AuthException

class AssistantPage extends StatefulWidget {
  @override
  _AssistantPageState createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Для автоскролла
  final ChatService _chatService = ChatService();
  
  List<ChatHistory> _messages = []; // Используем модель ChatHistory
  bool _isLoadingHistory = true; // Загрузка начальной истории
  bool _isSendingMessage = false; // Отправка сообщения / ожидание ответа AI
  String? _errorMessage; // Для отображения ошибок

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool scrollToBottom = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
    });

    try {
      final history = await _chatService.getChatHistory();
      if (!mounted) return;
      setState(() {
        _messages = history;
      });
      if (scrollToBottom) {
        _scrollToBottom();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        // TODO: Возможно, перенаправить на LoginPage при AuthException
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка загрузки истории: $e';
      });
    } finally {
       if (!mounted) return;
       setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSendingMessage) {
      return;
    }

    _messageController.clear();
    
    // Оптимистичное добавление сообщения пользователя (используем 'user')
    final userMessage = ChatHistory(message: messageText, senderType: 'user', createdAt: DateTime.now());
    if (!mounted) return;
    setState(() {
      _messages.add(userMessage);
      _isSendingMessage = true;
      _errorMessage = null;
    });
    _scrollToBottom(); // Сразу скроллим вниз

    try {
      await _chatService.sendMessage(messageText);
      // После успешной отправки загружаем историю снова, чтобы получить ответ AI
      await _loadHistory(scrollToBottom: true);
    } on AuthException catch (e) {
       if (!mounted) return;
       setState(() {
         _errorMessage = e.message;
         // Удаляем оптимистично добавленное сообщение при ошибке?
         _messages.remove(userMessage); 
         // TODO: Решить, нужно ли удалять + Показать SnackBar?
       });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка отправки: $e';
        _messages.remove(userMessage); // Удаляем оптимистично добавленное сообщение
        // TODO: Показать SnackBar?
      });
    } finally {
       if (!mounted) return;
       setState(() {
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    // Запрос подтверждения
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистить историю?'),
        content: Text('Вы уверены, что хотите удалить все сообщения в этом чате?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true; // Используем тот же индикатор
      _errorMessage = null;
    });

    try {
      await _chatService.clearHistory();
      if (!mounted) return;
      setState(() {
        _messages = []; // Очищаем локально
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка очистки истории: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  // Плавный скролл к последнему сообщению
  void _scrollToBottom() {
    // Используем SchedulerBinding, чтобы скролл произошел после отрисовки
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE95322),
              radius: 20,
              // TODO: Можно добавить иконку AI
              child: Icon(Icons.support_agent, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Виртуальный помощник',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Кнопка очистки истории
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: Colors.grey[600]),
            tooltip: 'Очистить историю',
            onPressed: _isLoadingHistory || _isSendingMessage ? null : _clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Область сообщений
            Expanded(
              child: _buildMessagesArea(),
            ),
            // Индикатор отправки/ожидания AI
            if (_isSendingMessage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('AI думает...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            // Поле ввода
            _buildMessageInputArea(),
          ],
        ),
      ),
      // Нижняя навигация остается без изменений
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFE95322),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               IconButton(
                 icon: Icon(Icons.home, color: Colors.white),
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => HomePage()),
                   );
                 },
               ),
               IconButton(
                 icon: Icon(Icons.edit, color: Colors.white),
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => CreateRecipePage()),
                   );
                 },
               ),
               IconButton(
                 icon: Icon(Icons.shopping_cart, color: Colors.white),
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => ProductListScreen()),
                   );
                 },
               ),
               IconButton(
                 icon: Icon(Icons.chat_bubble, color: Colors.white), // Иконка активной страницы
                 onPressed: () {}, // Уже на этой странице
               ),
               IconButton(
                 icon: Icon(Icons.person_outline, color: Colors.white),
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => ProfilePage()),
                   );
                 },
               ),
             ],
           ),
         ),
      ),
    );
  }

  // Виджет для отображения сообщений или статуса загрузки/ошибки
  Widget _buildMessagesArea() {
    if (_isLoadingHistory) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text('Ошибка', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _loadHistory, child: Text('Повторить попытку')),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'История сообщений пуста.\nЗадайте вопрос помощнику!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // Список сообщений
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top: 10, bottom: 4, left: 16, right: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        // Проверяем на 'user' (строчные)
        final isUserMessage = message.senderType == 'user'; 

        return Align(
          alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 10,
              left: isUserMessage ? 64 : 0,
              right: isUserMessage ? 0 : 64,
            ),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUserMessage ? Color(0xFFE95322) : Color(0xFFF3E9B5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: 16,
                color: isUserMessage ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  // Виджет для поля ввода сообщения
  Widget _buildMessageInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 120,
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Сообщение',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!), // Видимая граница
                  ),
                  enabledBorder: OutlineInputBorder( // Граница в обычном состоянии
                     borderRadius: BorderRadius.circular(14),
                     borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder( // Граница при фокусе
                     borderRadius: BorderRadius.circular(14),
                     borderSide: BorderSide(color: Color(0xFFE95322), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white, // Белый фон поля
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  isDense: true,
                  counterText: '',
                ),
                style: TextStyle(fontSize: 16),
                scrollPadding: EdgeInsets.all(20),
                textInputAction: TextInputAction.send, // Используем send
                onSubmitted: (_) => _sendMessage(), // Отправка по Enter на физической клавиатуре
                enabled: !_isSendingMessage, // Блокируем ввод во время отправки
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFE95322),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              // Блокируем кнопку во время отправки или если поле пустое
              onPressed: _isSendingMessage ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
} 