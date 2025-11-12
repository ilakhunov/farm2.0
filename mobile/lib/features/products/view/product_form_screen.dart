import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/product_repository.dart';
import '../models/product.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ProductRepository();
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String _category = 'vegetables';
  bool _isLoading = false;

  final List<String> _categories = [
    'vegetables',
    'fruits',
    'grains',
    'dairy',
    'meat',
    'other',
  ];

  final List<String> _units = ['kg', 'piece', 'liter', 'box', 'bag'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _category = widget.product!.category;
      _priceController.text = widget.product!.price.toString();
      _quantityController.text = widget.product!.quantity.toString();
      _unitController.text = widget.product!.unit;
      _imageUrlController.text = widget.product!.imageUrl ?? '';
    } else {
      _unitController.text = 'kg';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
      final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;

      if (widget.product != null) {
        // Обновление товара
        await _repository.updateProduct(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          category: _category,
          price: price,
          quantity: quantity,
          unit: _unitController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty 
              ? null 
              : _imageUrlController.text.trim(),
        );
      } else {
        // Создание нового товара
        await _repository.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          category: _category,
          price: price,
          quantity: quantity,
          unit: _unitController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty 
              ? null 
              : _imageUrlController.text.trim(),
        );
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product != null 
              ? 'Товар обновлен' 
              : 'Товар создан'),
        ),
      );
      
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Ошибка при сохранении товара';
      
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Редактировать товар' : 'Создать товар'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название товара *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название товара';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Категория *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryLabel(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите цену';
                        }
                        final price = double.tryParse(value.replaceAll(',', '.'));
                        if (price == null || price <= 0) {
                          return 'Цена должна быть больше 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('сум', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Количество *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите количество';
                        }
                        final quantity = double.tryParse(value.replaceAll(',', '.'));
                        if (quantity == null || quantity < 0) {
                          return 'Количество должно быть >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _unitController.text.isEmpty ? 'kg' : _unitController.text,
                      decoration: const InputDecoration(
                        labelText: 'Единица *',
                        border: OutlineInputBorder(),
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _unitController.text = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL изображения',
                  border: OutlineInputBorder(),
                  helperText: 'Опционально',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.product != null ? 'Сохранить изменения' : 'Создать товар'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'vegetables': 'Овощи',
      'fruits': 'Фрукты',
      'grains': 'Зерновые',
      'dairy': 'Молочные продукты',
      'meat': 'Мясо',
      'other': 'Другое',
    };
    return labels[category] ?? category;
  }
}

