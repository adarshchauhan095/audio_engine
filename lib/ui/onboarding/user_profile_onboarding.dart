import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../storage/user_profile_storage.dart';
import '../screens/therapy_entry_screen.dart';

class UserProfileOnboarding extends StatefulWidget {
  const UserProfileOnboarding({super.key});

  @override
  State<UserProfileOnboarding> createState() => _UserProfileOnboardingState();
}

class _UserProfileOnboardingState extends State<UserProfileOnboarding> {
  final PageController _pageController = PageController();
  final UserProfile _profile = UserProfile();
  final UserProfileStorage _storage = UserProfileStorage();

  int _currentIndex = 0;
  
  void _nextPage() {
    if (_currentIndex < 13) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndFinish();
    }
  }
  
  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndFinish() async {
    await _storage.saveUserProfile(_profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const TherapyEntryScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildOptionScreen({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedValue,
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(value);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (_currentIndex > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderScreen({
    required String title,
    required double min,
    required double max,
    required int divisions,
    required double value,
    required ValueChanged<double> onChanged,
    String Function(double)? labelBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Text(
            labelBuilder != null ? labelBuilder(value) : value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: labelBuilder != null ? labelBuilder(value) : value.toStringAsFixed(1),
            onChanged: (val) {
              setState(() {
                onChanged(val);
              });
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (_currentIndex > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinnitus Profile'),
        leading: _currentIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
        actions: [
          TextButton(
            onPressed: _saveAndFinish,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to force using options/buttons
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Screen 1
          _buildOptionScreen(
            title: 'How long have you had your tinnitus?',
            options: ['Less than 3 months', '3-12 months', '1-2 years', '2-5 years', 'More than 5 years'],
            selectedValue: _profile.tinnitusDuration,
            onChanged: (val) => setState(() => _profile.tinnitusDuration = val),
          ),
          // Screen 2
          _buildOptionScreen(
            title: 'How did your tinnitus start?',
            options: const ['Suddenly', 'Gradually', 'After loud noise', 'After stress', 'After infection', 'I’m not sure'],
            selectedValue: () {
              switch (_profile.tinnitusOnsetType) {
                case 'sudden': return 'Suddenly';
                case 'gradual': return 'Gradually';
                case 'afterNoise': return 'After loud noise';
                case 'afterStress': return 'After stress';
                case 'afterInfection': return 'After infection';
                default: return 'I’m not sure';
              }
            }(),
            onChanged: (val) {
              String mapped = 'unknown';
              if (val == 'Suddenly') mapped = 'sudden';
              if (val == 'Gradually') mapped = 'gradual';
              if (val == 'After loud noise') mapped = 'afterNoise';
              if (val == 'After stress') mapped = 'afterStress';
              if (val == 'After infection') mapped = 'afterInfection';
              setState(() => _profile.tinnitusOnsetType = mapped);
            },
          ),
          // Screen 3
          _buildOptionScreen(
            title: 'What does your tinnitus sound like?',
            options: const ['Pure tone', 'Hiss', 'Buzzing', 'Pulsating', 'Modulated', 'Narrowband noise', 'Mixed'],
            selectedValue: () {
              switch (_profile.toneType) {
                case 'pureTone': return 'Pure tone';
                case 'hiss': return 'Hiss';
                case 'buzzing': return 'Buzzing';
                case 'pulsating': return 'Pulsating';
                case 'modulated': return 'Modulated';
                case 'narrowband': return 'Narrowband noise';
                case 'mixed': return 'Mixed';
                default: return 'Pure tone';
              }
            }(),
            onChanged: (val) {
              String mapped = 'pureTone';
              if (val == 'Hiss') mapped = 'hiss';
              if (val == 'Buzzing') mapped = 'buzzing';
              if (val == 'Pulsating') mapped = 'pulsating';
              if (val == 'Modulated') mapped = 'modulated';
              if (val == 'Narrowband noise') mapped = 'narrowband';
              if (val == 'Mixed') mapped = 'mixed';
              setState(() => _profile.toneType = mapped);
            },
          ),
          // Screen 4
          _buildOptionScreen(
            title: 'How stable is your tinnitus?',
            options: const ['Stable', 'Fluctuating', 'Intermittent'],
            selectedValue: () {
              switch (_profile.toneStability) {
                case 'stable': return 'Stable';
                case 'fluctuating': return 'Fluctuating';
                case 'intermittent': return 'Intermittent';
                default: return 'Stable';
              }
            }(),
            onChanged: (val) => setState(() => _profile.toneStability = val.toLowerCase()),
          ),
          // Screen 5
          _buildOptionScreen(
            title: 'Where do you perceive your tinnitus?',
            options: ['Left ear', 'Right ear', 'Both ears', 'Inside the head', 'It shifts'],
            selectedValue: _profile.location == 'insideHead' ? 'Inside the head' : _profile.location,
            onChanged: (val) => setState(() => _profile.location = val),
          ),
          // Screen 6
          _buildSliderScreen(
            title: 'What is the approximate pitch of your tinnitus?',
            min: 100,
            max: 12000,
            divisions: 119,
            value: _profile.selfReportedFrequencyHz,
            onChanged: (val) => _profile.selfReportedFrequencyHz = val,
            labelBuilder: (val) => '${val.toInt()} Hz',
          ),
          // Screen 7
          _buildSliderScreen(
            title: 'How loud is your tinnitus?',
            min: 0,
            max: 10,
            divisions: 10,
            value: _profile.selfReportedLoudness,
            onChanged: (val) => _profile.selfReportedLoudness = val,
          ),
          // Screen 8
          _buildSliderScreen(
            title: 'How dominant is your tinnitus in daily life?',
            min: 0,
            max: 10,
            divisions: 10,
            value: _profile.dominance,
            onChanged: (val) => _profile.dominance = val,
          ),
          // Screen 9
          _buildOptionScreen(
            title: 'How often do you notice your tinnitus?',
            options: ['Rarely', 'Sometimes', 'Often', 'Most of the day', 'All day'],
            selectedValue: _profile.awareness >= 80 ? 'All day' : 
                           _profile.awareness >= 60 ? 'Most of the day' :
                           _profile.awareness >= 40 ? 'Often' :
                           _profile.awareness >= 20 ? 'Sometimes' : 'Rarely',
            onChanged: (val) {
              double awarenessVal = 50.0;
              if (val == 'Rarely') awarenessVal = 10.0;
              if (val == 'Sometimes') awarenessVal = 30.0;
              if (val == 'Often') awarenessVal = 50.0;
              if (val == 'Most of the day') awarenessVal = 70.0;
              if (val == 'All day') awarenessVal = 90.0;
              setState(() => _profile.awareness = awarenessVal);
            },
          ),
          // Screen 10
          _buildOptionScreen(
            title: 'Does your tinnitus change in noisy environments?',
            options: const ['Louder', 'Quieter', 'Unchanged'],
            selectedValue: () {
              switch (_profile.reactivityToNoise) {
                case 'louder': return 'Louder';
                case 'quieter': return 'Quieter';
                case 'unchanged': return 'Unchanged';
                default: return 'Unchanged';
              }
            }(),
            onChanged: (val) => setState(() => _profile.reactivityToNoise = val.toLowerCase()),
          ),
          // Screen 11
          _buildOptionScreen(
            title: 'Does your tinnitus change in silence?',
            options: const ['Louder', 'Quieter', 'Unchanged'],
            selectedValue: () {
              switch (_profile.reactivityToSilence) {
                case 'louder': return 'Louder';
                case 'quieter': return 'Quieter';
                case 'unchanged': return 'Unchanged';
                default: return 'Unchanged';
              }
            }(),
            onChanged: (val) => setState(() => _profile.reactivityToSilence = val.toLowerCase()),
          ),
          // Screen 12
          _buildSliderScreen(
            title: 'Does stress affect your tinnitus?',
            min: 0,
            max: 10,
            divisions: 10,
            value: _profile.reactivityToStress,
            onChanged: (val) => _profile.reactivityToStress = val,
          ),
          // Screen 13
          _buildSliderScreen(
            title: 'Does tiredness affect your tinnitus?',
            min: 0,
            max: 10,
            divisions: 10,
            value: _profile.reactivityToFatigue,
            onChanged: (val) => _profile.reactivityToFatigue = val,
          ),
          // Screen 14
          _buildOptionScreen(
            title: 'When is your tinnitus strongest?',
            options: ['Morning', 'Evening', 'Same throughout the day'],
            selectedValue: _profile.morningIntensity > _profile.eveningIntensity ? 'Morning' :
                           _profile.eveningIntensity > _profile.morningIntensity ? 'Evening' : 'Same throughout the day',
            onChanged: (val) {
              if (val == 'Morning') {
                _profile.morningIntensity = 8.0;
                _profile.eveningIntensity = 4.0;
              } else if (val == 'Evening') {
                _profile.morningIntensity = 4.0;
                _profile.eveningIntensity = 8.0;
              } else {
                _profile.morningIntensity = 5.0;
                _profile.eveningIntensity = 5.0;
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
