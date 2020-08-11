// /mob/living/silicon/pai/proc/paiInterface()
import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, Flex, LabeledList, NoticeBox, Section, Table, Collapsible } from '../components';
import { Window } from '../layouts';

export const PAIPersonality = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window>
      <Window.Content>
        Poggers
      </Window.Content>
    </Window>
  );
};
