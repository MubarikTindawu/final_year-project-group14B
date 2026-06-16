import 'package:flutter/material.dart';

class CropData {
  // Standardized Reference Dataset for Group 14B Farm Manager
  static const Map<String, Map<String, dynamic>> standards = {
    'Corn (Maize)': {
      'duration': 90,
      'variety': ['Obatanpa', 'Omankwa', 'Abontem'],
      'icon': '🌽',
      'stages': [
        {'days': 7, 'task': 'Seedling Stage', 'message': 'Time to apply NPK 15-15-15 fertilizer.'},
        {'days': 21, 'task': 'Vegetative Stage', 'message': 'First weeding and Top Dressing (Urea) required.'},
        {'days': 55, 'task': 'Flowering Stage', 'message': 'Check moisture and monitor for Fall Armyworm.'},
      ],
    },
    'Tomato': {
      'duration': 80,
      'variety': ['Pectomech', 'Power', 'Roma'],
      'icon': '🍅',
      'stages': [
        {'days': 14, 'task': 'Transplant Check', 'message': 'Check for seedling survival and replace dead ones.'},
        {'days': 45, 'task': 'Flowering', 'message': 'Apply Calcium-based fertilizer to prevent blossom end rot.'},
        {'days': 75, 'task': 'Ripening', 'message': 'Check fruit color. Harvest starts in 5-10 days.'},
      ],
    },
    'Cabbage': {
      'duration': 85,
      'variety': ['KK Cross', 'Oxylus', 'Tropica'],
      'icon': '🥬',
      'stages': [
        {'days': 14, 'task': 'Establishment', 'message': 'Check for Diamondback moth larvae.'},
        {'days': 30, 'task': 'Head Initiation', 'message': 'Apply NPK and ensure consistent watering.'},
        {'days': 70, 'task': 'Maturity Check', 'message': 'Squeeze heads to check firmness for harvest.'},
      ],
    },
    'Pepper': {
      'duration': 100,
      'variety': ['Legon 18', 'Moni', 'Birdseye'],
      'icon': '🌶️',
      'stages': [
        {'days': 21, 'task': 'Growth Check', 'message': 'Apply first dose of NPK and check for aphids.'},
        {'days': 60, 'task': 'Fruit Set', 'message': 'Ensure consistent watering to prevent flower drop.'},
      ],
    },
    'Yam': {
      'duration': 240,
      'variety': ['Puna', 'Laribako', 'Dente'],
      'icon': '🥔',
      'stages': [
        {'days': 30, 'task': 'Sprouting', 'message': 'Ensure stakes are ready for the vines to climb.'},
        {'days': 120, 'task': 'Tuber Initiation', 'message': 'Perform second weeding and mound maintenance.'},
      ],
    },
    'Rice': {
      'duration': 120,
      'variety': ['AGRA Rice', 'Jasmine', 'Nerica'],
      'icon': '🌾',
      'stages': [
        {'days': 21, 'task': 'Tillering', 'message': 'Apply first dose of Urea. Maintain thin water layer.'},
        {'days': 85, 'task': 'Grain Protection', 'message': 'Guard against birds and drain field 2 weeks before harvest.'},
      ],
    },
    'Cassava': {
      'duration': 360,
      'variety': ['Bankyehemaa', 'Ampong', 'Sika Bankye'],
      'icon': '🌱',
      'stages': [
        {'days': 30, 'task': 'Rooting', 'message': 'Perform first weeding and check for mosaic disease.'},
        {'days': 180, 'task': 'Bulking', 'message': 'Tuber expansion is peaking. Keep soil hilled up.'},
      ],
    },
    'Groundnut': {
      'duration': 120,
      'variety': ['Chinese', 'Shitaochi', 'Sinkazie'],
      'icon': '🥜',
      'stages': [
        {'days': 40, 'task': 'Pegging Stage', 'message': 'Flowers are dropping pegs. Do not disturb the soil.'},
        {'days': 100, 'task': 'Maturity', 'message': 'Check leaf yellowing and pull a few pods to test.'},
      ],
    },
    'Soyabeans': {
      'duration': 100,
      'variety': ['Jenguma', 'Quarshie', 'Anidaso'],
      'icon': '🌱',
      'stages': [
        {'days': 14, 'task': 'Inoculation Check', 'message': 'Check root nodules for nitrogen fixation.'},
        {'days': 45, 'task': 'Pod Formation', 'message': 'Critical water stage. Ensure soil remains moist.'},
      ],
    },
    'Bambara Beans': {
      'duration': 130,
      'variety': ['Black-eyed', 'Cream', 'Red'],
      'icon': '🫘',
      'stages': [
        {'days': 35, 'task': 'Flowering', 'message': 'Check for moisture and weed competition.'},
      ],
    },
    'Cocoa': {
      'duration': 1095,
      'variety': ['Hybrid Cocoa', 'Amazonian', 'Amelonado'],
      'icon': '🍫',
      'stages': [
        {'days': 30, 'task': 'Seedling Care', 'message': 'Check for capsid insects and maintain shading.'},
        {'days': 180, 'task': 'Pruning', 'message': 'Light pruning to improve aeration and sunlight.'},
      ],
    },
  };

  // Helper methods for the UI
  static List<String> get cropNames => standards.keys.toList();

  static List<String> getVarieties(String cropName) {
    return List<String>.from(standards[cropName]?['variety'] ?? ['Standard']);
  }

  static int getDuration(String cropName) {
    return standards[cropName]?['duration'] ?? 90;
  }
}