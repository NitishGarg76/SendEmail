import {View, Platform, NativeModules, Alert} from 'react-native';
const App=()=>{
  const { EmailModule } = NativeModules;

 const handleEmail = () => {

   Platform.OS === 'android'

     ? EmailModule.sendEmail(SUPPORT_EMAIL, '', '')

         .then(() => {

           Alert.alert('Email sent successfully');

         })

         .catch(error => {

           Alert.alert('Error', error.message); 

         })

     : EmailModule.sendEmail(SUPPORT_EMAIL, '', '');

 };
  return(
    <View></View>)
}
