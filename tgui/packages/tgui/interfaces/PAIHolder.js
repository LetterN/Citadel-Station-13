/**
 * This is the interface the holder gets
 */
import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, Section, Table, Collapsible } from '../components';
import { Window } from '../layouts';

export const PAIHolder = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    pAI_installed = false,
    pAI_info = {}, // installed pAI metadata
    pAI_personalities = null, // array of /datum/paiCandidate
    pAI_owner = false,
  } = data;
  const {
    name,
    zeroth,
    aditional_laws = [],
    canholo = true,
    radio = true,
    radio_tx = true,
    radio_rx = true,
    radio_short = false, // emp act
  } = pAI_info;
  return (
    <Window resizable>
      <Window.Content scrollable>
        {pAI_installed ? (
          "vvvv"
        ) : (
          <Fragment>
            <NoticeBox>
              No personality installed.<br />
              Searching for a personality... Press view available
              personalities to notify potential candidates.
              <Button
                content="View available personalities"
                onclick={() => act('request')} />
            </NoticeBox>
            {pAI_personalities ? (
              <Section title="Personalities">
                Requesting AI personalities from central database...
                If there are no entries, or if a suitable entry is not listed,
                check again later as more personalities may be added.
                <Table>
                  {pAI_personalities?.map(pai_mob => (
                    <Table.Row
                      key={pai_mob.name}
                      className="candystripe">
                      <Table.Cell
                        buttons={(
                          <Button
                            icon="download"
                            onclick={() => act('download', {
                              key: pai_mob.key,
                            })} />
                        )}>
                        <b>{pai_mob.name}</b>
                        {pai_mob.description.len >= 350 ? ( // 350 len preview
                          `${pai_mob.description.substr(0, 350)}...`
                        ) : (
                          pai_mob.description
                        )}
                      </Table.Cell>
                      <Table.Cell>
                        <Collapsible
                          title="More Info">
                          <PAIInfo pai_info={pai_mob} />
                        </Collapsible>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            ) : (
              <Section title="Personalities">
                Requesting AI personalities from central database...
                If there are no entries, or if a suitable entry is not listed,
                check again later as more personalities may be added.
              </Section>
            )}
          </Fragment>
        )}
      </Window.Content>
    </Window>
  );
};

// Used for info and editing
export const PAIInfo = (props, context) => {
  const { act } = useBackend(context);
  const {
    editing,
    pai_info,
  } = props;
  return (
    <LabeledList>
      {!!editing && ( // button with a penpaper for change?
        <LabeledList.Item
          label="Name"
          buttons={(
            <Button
              icon="pen"
              tooltip={`
              What you plan to call yourself.
              Suggestions: Any character name you would
              choose for a station character OR an AI.`}
              onclick={() => act('edit', {
                what: 'name',
              })} />
          )}>
          {pai_info.name}
        </LabeledList.Item>
      )}
      <LabeledList.Item
        label="Description"
        buttons={editing && (
          <Button
            icon="pen"
            tooltip={`
            What sort of pAI you typically play;
            your mannerisms, your quirks, etc.
            This can be as sparse or as detailed as you like.
            `}
            onclick={() => act('edit', {
              what: 'desc',
            })} />
        )}>
        {pai_info.description}
      </LabeledList.Item>
      <LabeledList.Item
        label="Prefered Role"
        tooltip={`
        This doesn't have to be limited to just station jobs.
        Pretty much any general descriptor for
        what you'd like to be doing works here.
        `}
        buttons={editing && (
          <Button
            icon="pen"
            onclick={() => act('edit', {
              what: 'role',
            })} />
        )}>
        {pai_info.role}
      </LabeledList.Item>
      <LabeledList.Item
        label="OOC Comments"
        tooltip={`
        Anything you'd like to address specifically
        to the player reading this in an OOC manner.
        Feel free to leave this blank if you want.
        `}
        buttons={editing && (
          <Button
            icon="pen"
            onclick={() => act('edit', {
              what: 'ooc',
            })} />
        )}>
        {pai_info.comments}
      </LabeledList.Item>
    </LabeledList>
  );
};
