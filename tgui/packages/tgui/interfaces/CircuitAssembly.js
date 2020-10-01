import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';

export const CircuitAssembly = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    hasBattery = true,
    cellCharge = 0,
    cellMaxCharge = Infinity,
    partSize = 0,
    partMaxSize = Infinity,
    partCompex = 0,
    partMaxComplex  = Infinity,
    assemblyName = "name me",
    componentsBuiltIn = [], // array
    ic_components = [], // array, added ic_ because might conflict
  } = data;
  return (
    <Window resizable>
      <Window.Content scrollable>
        <Fragment>
          <Section>
            <LabeledList>
              <LabeledList.Item label="Name">
                <Button.Input
                  icon="fa-pen"
                  defaultValue={assemblyName}
                  onCommit={(e, value) => act('something', { 'name': value })}>
                    {assemblyName}
                </Button.Input>
              </LabeledList.Item>
            </LabeledList>
          </Section>
          <Section title="Components">
            {!!componentsBuiltIn?.length && (
              <Section title="Built in">
                {`CircuitObjects foor loop here`}
              </Section>
            )}
            <Section title="Removable">
              {`CircuitObjects foor loop here`}
            </Section>
          </Section>
        </Fragment>
      </Window.Content>
    </Window>
  );
};

export const CircuitObjects = (props, context) => {
  return (
    "E"
  );
};
